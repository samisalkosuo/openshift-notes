#!/bin/sh


if [[ "$OMG_OCP_PULL_SECRET_FILE" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

if [ ! -f "$OMG_OCP_PULL_SECRET_FILE" ]; then
  echo "Pull secret $OMG_OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
  exit 1
fi

set -e

#OpenShift install dir, used while installing OpenShift
#holds kubeconfig authentication file in auth-subdirectory
__dir_suffix=${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN}
__openshift_install_dir=~/ocp-install-${__dir_suffix}

#certificate dir
__certificates_dir=certs/

#images dir
__dist_dir=ocp-images/
#repo in mirror registry
OPENSHIFT_REPO=openshift/release

#SSH key file
__ssh_type=rsa
__ssh_key_file=~/.ssh/id_rsa

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

  local __pull_secret_json=$(cat $OMG_OCP_PULL_SECRET_FILE | jq -c '')

  createSSHKey


  echo "creating install-config.yaml..."
  local __install_cfg_file=/tmp/install-config.yaml
  #create install-config.yaml
  cat > ${__install_cfg_file} << EOF
apiVersion: v1
metadata:
  name: ${OMG_OCP_CLUSTER_NAME}
baseDomain: ${OMG_OCP_DOMAIN}
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
  - cidr: ${OMG_OCP_NODE_NETWORK_CIDR}
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {} 
fips: false
pullSecret: '${__pull_secret_json}'
EOF

  #add http proxy
  if [[ "$OMG_OCP_HTTP_PROXY" != "" ]]; then
    echo "setting HTTP proxy to install-config.yaml..."
    if [[ "$OMG_OCP_NO_PROXY" != "" ]]; then
      OCP_NO_PROXY=".apps.${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN},$OMG_OCP_NO_PROXY"
    else 
      OCP_NO_PROXY=".apps.${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN}"
    fi
    cat >> ${__install_cfg_file} << EOF
proxy:
  httpProxy: ${OMG_OCP_HTTP_PROXY}
  httpsProxy: ${OMG_OCP_HTTPS_PROXY}
  noProxy: ${OMG_OCP_NO_PROXY}
EOF
  fi


  #add ssh key to install config file
  echo -n "sshKey: '" >> ${__install_cfg_file} && cat ${__ssh_key_file}.pub | sed "s/$/\'/g" >> ${__install_cfg_file}

  #start airgapped install 
  #add CA certificate, if it exists
  local __ca_cert_file=$__certificates_dir/CA_${OMG_OCP_DOMAIN}.crt
  if [ -f $__ca_cert_file ]; then
    echo "additionalTrustBundle: |" >> $__install_cfg_file
    cat ${__ca_cert_file} | sed 's/^/\ \ \ \ \ /g' >> $__install_cfg_file
  fi

  local __mirror_output_file=$__dist_dir/mirror-output.txt
  if [ -f $__mirror_output_file ]; then
    #airgapped environment, if  mirror-output.txt exists,  add imageContentSources
    local __registry=$OMG_OCP_MIRROR_REGISTRY_HOST_NAME.$OMG_OCP_DOMAIN
    local __ocp_repo=openshift/release
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

  if [ -f images.yaml ]; then
    #airgapped environment, if images.yaml exists,  add imageContentSources
    echo "imageContentSources:" >> ${__install_cfg_file}
    cat images.yaml >> ${__install_cfg_file}
  fi
  #end airgapped install 

  #remove empty lines if there are any
  sed -i '/^[[:space:]]*$/d' $__install_cfg_file

  #backup of install-config.yaml
  #local timestamp=$(date "+%Y%m%d%H%M%S")
  #cp ${__install_cfg_file} /tmp/install-config-${timestamp}.yaml

  #copy install-config file to install-directory
  cp $__install_cfg_file $__openshift_install_dir/

  echo "creating manifest files..."
  local __current_dir=$(pwd)
  cd $__openshift_install_dir/
  openshift-install create manifests --dir=./
  if [[ "$OMG_OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
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

function createSSHKey
{
  if [ -f ${__ssh_key_file} ]; then
    echo "SSH key already created."
  else
    echo "Creating new SSH key..."
    ssh-keygen -t ${__ssh_type} -N '' -f ${__ssh_key_file}
  fi 
}

function error
{
    echo $1
    exit 1
}

ocpPrepareInstall
