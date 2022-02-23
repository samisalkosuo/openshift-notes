#functions for openshift install

function ocpStartInstall
{
    echo "1. Boot up bootstrap node."
    echo "2. (Optional) verify that you can access bootstrap using 'ssh core@bootstrap'."
    echo "3. Boot up all master nodes."
    echo "4. (Optional) verify that you can access masters using 'ssh core@masterX'."
    echo "5. Wait for bootstrap to be complete. Use '$0 ocp-complete-bootstrap'."
    echo "6. Open environment.sh and set' OCP_BOOTSTRAP_COMPLETE=yes'."
    echo "7. 'source environment.sh'."
    echo "8. Setup load balancer without bootstrap. '$0 setup-lb'."
    echo "9. Boot up at least two worker nodes."
    echo "10. Approve worker node csrs. Use '$0 ocp-get-csr' and '$0 ocp-approve-csr'."
    echo "11. Wait for all cluster operators to be available. Use '$0 ocp-cluster-operators'."
    echo "12. Complete installation. Use '$0 ocp-complete-install'."
}

function ocpCompleteInstall
{
  local __current_dir=$(pwd)
  cd $__openshift_install_dir/
  openshift-install --dir=./ wait-for install-complete 2>&1 | tee ${__omg_runtime_dir}/install-complete.txt
  cd $__current_dir
}


function getKubeConfig
{
    local __kubeconfig="notfound"
    if [ -d "${__openshift_ipi_install_dir}" ]
    then
      __kubeconfig="${__openshift_ipi_install_dir}/auth/kubeconfig"
    fi

    if [ -d "${__openshift_install_dir}" ]
    then
      __kubeconfig="${__openshift_install_dir}/auth/kubeconfig"
    fi

    echo $__kubeconfig
}

function ocpGetClusterOperators
{
    
    (export KUBECONFIG=$(getKubeConfig); watch -n3 oc get clusteroperators)
}

function ocpGetNodes
{
  (export KUBECONFIG=$(getKubeConfig); watch -n3 oc get nodes)

}

function ocpGetCSR
{    
    (export KUBECONFIG=$(getKubeConfig); watch -n3 oc get csr)
}

function ocpApproveAllCSRs
{
    (export KUBECONFIG=$(getKubeConfig); oc get csr |grep Pending |awk '{print "oc adm certificate approve " $1}' |sh)
    
}

function ocpCompleteBootstrap
{
  echo "Waiting for bootstrap..."
  if [ ! -d "${__openshift_install_dir}" ]
  then
      echo "Directory ${__openshift_install_dir} does not exist." 
      error "Have you prepared to install OpenShift?" 
  fi
  local __current_dir=$(pwd)
  #local timestamp=$(date "+%Y%m%d%H%M%S")
  cd $__openshift_install_dir/
  openshift-install --dir=./ wait-for bootstrap-complete --log-level debug 2>&1 | tee ${__omg_runtime_dir}/bootstrap-complete.txt
  cd $__current_dir
  echo "Waiting for bootstrap...done."
}


function ocpPrepareInstall
{
  echo "Preparing OpenShift install..."
  if [ -d "${__openshift_install_dir}" ]
  then
      echo "Directory ${__openshift_install_dir} exists." 
      echo "Have you already installed OpenShift?" 
      error "Remove ${__openshift_install_dir} and try again."
  fi

  #create install directory
  mkdir -p ${__openshift_install_dir}

  local __pull_secret_json=$(cat $OCP_PULL_SECRET_FILE | jq -c '')

  createSSHKey


  echo "creating install-config.yaml..."
  local __install_cfg_file=${__omg_runtime_dir}/install-config.yaml
  #create install-config.yaml
  cat > ${__install_cfg_file} << EOF
apiVersion: v1
metadata:
  name: ${OCP_CLUSTER_NAME}
baseDomain: ${OCP_DOMAIN}
controlPlane:
  name: master
  platform: {}
  hyperthreading: Enabled
  replicas: 3
compute:
- name: worker
  platform: {}
  hyperthreading: Enabled
  replicas: 0
networking:
  clusterNetworks:
  - cidr: 10.136.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: ${OCP_NODE_NETWORK_CIDR}
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {} 
fips: false
pullSecret: '${__pull_secret_json}'
EOF

  #add http proxy
  if [[ "$OCP_HTTP_PROXY" != "" ]]; then
    echo "setting HTTP proxy to install-config.yaml..."
    if [[ "$OCP_NO_PROXY" != "" ]]; then
      OCP_NO_PROXY=".apps.${OCP_CLUSTER_NAME}.${OCP_DOMAIN},$OCP_NO_PROXY"
    else 
      OCP_NO_PROXY=".apps.${OCP_CLUSTER_NAME}.${OCP_DOMAIN}"
    fi
    cat > ${__install_cfg_file} << EOF
proxy:
  httpProxy: ${OCP_HTTP_PROXY}
  httpsProxy: ${OCP_HTTPS_PROXY}
  noProxy: ${OCP_NO_PROXY}
EOF
  fi


  #add ssh key to install config file
  echo -n "sshKey: '" >> ${__install_cfg_file} && cat ${__ssh_key_file}.pub | sed "s/$/\'/g" >> ${__install_cfg_file}

  #start airgapped install 
  #add CA certificate, if it exists
  local __ca_cert_file=$__certificates_dir/CA_${OCP_DOMAIN}.crt
  if [ -f $__ca_cert_file ]; then
    echo "additionalTrustBundle: |" >> $__install_cfg_file
    cat ${__ca_cert_file} | sed 's/^/\ \ \ \ \ /g' >> $__install_cfg_file
  fi

  local __mirror_output_file=$__dist_dir/mirror-output.txt
  if [ -f $__mirror_output_file ]; then
    #airgapped environment, if  mirror-output.txt exists,  add imageContentSources
    local __registry=${__mirror_registry_base_name}.${OCP_DOMAIN}:${__mirror_registry_port}
    local __ocp_repo=$__ocp_local_repository
    cat >> ${__install_cfg_file} << EOF
imageContentSources: 
- mirrors:
  - ${__registry}/${__ocp_repo}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${__registry}/${__ocp_repo}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
  fi

  #end airgapped install 

  #remove empty lines if there are any
  sed -i '/^[[:space:]]*$/d' $__install_cfg_file

  #backup of install-config.yaml
  #local timestamp=$(date "+%Y%m%d%H%M%S")
  #cp ${__install_cfg_file} ${__omg_runtime_dir}/install-config-${timestamp}.yaml

  #copy install-config file to install-directory
  cp $__install_cfg_file $__openshift_install_dir/

  echo "creating manifest files..."
  local __current_dir=$(pwd)
  cd $__openshift_install_dir/
  openshift-install create manifests --dir=./
  if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    #when using  user-provisioned infrastructure installation, master nodes are schedulable
    #make master unschedulable if not using three node cluster
    echo "configuring master nodes unschedulable..."
    sed -i  "s/mastersSchedulable: true/mastersSchedulable: false/g" manifests/cluster-scheduler-02-config.yml
  fi

  echo "creating ignition files..."
  openshift-install create ignition-configs --dir=./
  
  echo "copying ignition files to Apache server..."
  local htmlDir=/var/www/html
  #delete existing ignition files
  rm -f $htmlDir/ignition/*ign
  chmod 644 *ign
  mv *ign $htmlDir/ignition
  #setting SELinux
  chcon -R -h -t httpd_sys_content_t $htmlDir/ignition

  cd $__current_dir

  echo "Preparing OpenShift install...done."

}


