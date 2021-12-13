#functions for openshift VSphere IPI install 


function ocpIPIInstall
{
  if [ -d "${__openshift_ipi_install_dir}" ]
  then
      echo "Directory ${__openshift_ipi_install_dir} exists." 
      echo "Have you already installed OpenShift?" 
      error "Remove ${__openshift_ipi_install_dir} and try again."
  fi
  mkdir -p ${__openshift_ipi_install_dir}

    set +e
    local __ping=$(ping -c 1 ${OCP_VSPHERE_VCENTER_FQDN})
    if [[ $? != 0 ]]; then
      echo "vCenter FQDN '${OCP_VSPHERE_VCENTER_FQDN}' not found."
      error "Make sure it is found from DNS."
    fi

    set -e

  local __pull_secret_json=$(cat $OCP_PULL_SECRET_FILE | jq -c '')

  createSSHKey

    local __sshKey=$(cat ${__ssh_key_file}.pub)
    local __cdir=$(pwd)    
    cd ${__omg_runtime_dir}
    local __certs=$(cat certs/lin/*.0 | sed 's/^/\ \ \ \ \ /g')
    cat > install-config.yaml << EOF
#For VSPhere IPI install
apiVersion: v1
baseDomain: ${OCP_DOMAIN}
metadata:
  name: ${OCP_CLUSTER_NAME}
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    vsphere: 
      cpus: ${OCP_IPI_MASTER_CPU}
      coresPerSocket: 1
      memoryMB: ${OCP_IPI_MASTER_RAM}
      osDisk:
        diskSizeGB: ${OCP_IPI_MASTER_DISK_GB}
  replicas: 3
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: 
    vsphere: 
      cpus: ${OCP_IPI_WORKER_CPU}
      coresPerSocket: 1
      memoryMB: ${OCP_IPI_WORKER_RAM}
      osDisk:
        diskSizeGB: ${OCP_IPI_WORKER_DISK_GB}
  replicas: ${OCP_IPI_WORKER_COUNT}
networking:
  clusterNetwork:
  - cidr: 10.124.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: ${OCP_NODE_NETWORK_CIDR}
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  vsphere:
    vCenter: ${OCP_VSPHERE_VCENTER_FQDN}
    username: ${OCP_VSPHERE_USER}
    password: ${OCP_VSPHERE_PASSWORD}
    cluster: ${OCP_VSPHERE_CLUSTER}
    datacenter: ${OCP_VSPHERE_DATACENTER}
    folder: ${OCP_VSPHERE_FOLDER}
    defaultDatastore: ${OCP_VSPHERE_DATASTORE}
    network: ${OCP_VSPHERE_NETWORK}
    apiVIP: ${OCP_VSPHERE_VIRTUAL_IP_API}
    ingressVIP: ${OCP_VSPHERE_VIRTUAL_IP_INGRESS}
publish: External
pullSecret: '${__pull_secret_json}'
sshKey: |
  ${__sshKey}
additionalTrustBundle: |
${__certs}
EOF
    cd ${__openshift_ipi_install_dir}
    cp ${__omg_runtime_dir}/install-config.yaml .
    openshift-install create cluster --dir=./ --log-level=debug 2>&1 | tee ${__omg_runtime_dir}/install-complete.txt

    cd ${__cdir}
}

function ocpIPIDestroy
{
    local __cdir=$(pwd)
    cd ${__openshift_ipi_install_dir}
    openshift-install destroy cluster --log-level=debug
    cd ${__cdir}

}

function extractVCenterCerts
{
    echo "Extracting VCenter certs and updating system trust..."
#    echo "Checking certificates..."
#    awk -v cmd='openssl x509 -noout -subject' '
#        /BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-bundle.crt 2> /dev/null | grep "${OCP_VSPHERE_VCENTER_FQDN}"
    local __cdir=$(pwd)
        
    cd ${__omg_runtime_dir}
    curl -k https://${OCP_VSPHERE_VCENTER_FQDN}/certs/download.zip > vcenter_certs.zip 2> /dev/null
    unzip -o vcenter_certs.zip &> /dev/null
    cp certs/lin/* /etc/pki/ca-trust/source/anchors
    update-ca-trust extract

    cd $__cdir
    
    echo "Extracting VCenter certs and updating system trust...done."

}
