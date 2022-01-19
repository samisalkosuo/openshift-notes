#!/bin/bash

#domain to be used in CA certificate and server FQDN (for example registry.forum.lab)
DOMAIN=forum.lab
CLUSTER_NAME=ocp

#OCP version to install/upgrade
#check https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
#for desired version 
OCP_VERSION=4.8.19

#OCP RHCOS version to be used to download RHCOS images
#Find correct RHCOS major release and version from
#https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/
#match RHCOS with chosen OpenShift
OCP_RHCOS_MAJOR_RELEASE=4.8
OCP_RHCOS_VERSION=4.8.14

#CIDR of servers where OpenShift is installed
OPENSHIFT_NODE_NETWORK_CIDR=1.2.0.0/16


#pull secret file to mirror images from Red Hat
OCP_PULL_SECRET_FILE=/root/pull-secret.json

#cert dir
CERT_DIR=$(pwd)/certs

#registry variables
REGISTRY_HOST=registry.forum.lab
REGISTRY_USER_NAME=admin
REGISTRY_USER_PASSWORD=passw0rd

#webserver variables
#webserver hostname hostname + DOMAIN
WEBSERVER_HOSTNAME=webserver

#openshift install directory
OPENSHIFT_INSTALL_DIR=$(pwd)/install-${CLUSTER_NAME}-${OCP_VERSION}
OMG_RUNTIME_DIR=/tmp
OPENSHIFT_REPO=openshift/release
OCP_THREE_NODE_CLUSTER=no

#SSH key file
SSH_TYPE=rsa
SSH_KEY_FILE=~/.ssh/id_rsa

KUBETERMINAL_TAG=latest

#client versions

#IBM Cloud CLI (cloudctl) version
#check latest version from https://github.com/IBM/cloud-pak-cli/releases
CLOUDCTL_VERSION=3.12.1

#grpcurl version
#check latest version from https://github.com/fullstorydev/grpcurl/releases/
GRPCURL_VERSION=1.8.5


function usage
{
  echo "OpenShift installer helper for airgapped OpenShift installations."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo ""
  echo "  prepare-httpd-tftp-jump       - Prepare httpd/tftp in jump server."
  echo "  prepare-httpd-tftp-airgapped  - Prepare httpd/tftp in airgapped server."
  echo "  prepare-bastion-jump          - Prepare bastion in jump server."
  echo "  prepare-bastion-airgapped     - Prepare bastion in airgapped server, including setup OpenShift install files."
  echo "  setup-haproxy                 - Set up haproxy."
  echo "  setup-openshift-install       - Setup OpenShift install files."
  echo "  ocp-complete-bootstrap        - Complete bootstrap."
  echo "  ocp-csr                       - Watch CSRs."
  echo "  ocp-nodes                     - Watch nodes."
  echo "  ocp-approve-csr               - Approve all pending CSRs."
  echo "  ocp-cluster-operators         - Watch cluster operators."
  echo "  ocp-complete-install          - Complete installation."
  echo ""
  exit 1
}


DIST_DIR=$(pwd)/dist-omg

THIS_SCRIPT_NAME=$0

set -e 

function error
{
    echo $1
    exit 1
    #kill -INT $$
}


function downloadFile
{
  #naming conventions
  #kernel: rhcos-<version>-live-kernel-<architecture>
  #initramfs: rhcos-<version>-live-initramfs.<architecture>.img
  #rootfs: rhcos-<version>-live-rootfs.<architecture>.img

  local dlurl=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${__release}/${__version}
  local dir=$2
  mkdir -p ${dir}
  if [ -f ${dir}/$1 ]; then
    echo "${dir}/$1 already downloaded."
  else
    wget --directory-prefix=${dir} ${dlurl}/$1
  fi 
}

function downloadRHCOSBinaries
{
    local __release=$OCP_RHCOS_MAJOR_RELEASE
    local __version=$OCP_RHCOS_VERSION
    local __architecture=x86_64
    local __dir=${DIST_DIR}/rhcos
    mkdir -p $__dir

    echo "Downloading RHCOS ${__version} kernel to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-kernel-${__architecture} $__dir

    echo "Downloading RHCOS ${__version} initramfs to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-initramfs.${__architecture}.img $__dir

    echo "Downloading RHCOS ${__version} rootfs to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-rootfs.${__architecture}.img $__dir

    echo "Downloading RHCOS ${__version} OVA to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-vmware.${__architecture}.ova $__dir
    
}

function createDistributionPackage 
{
    local cdir=$(pwd)
    local base=$(basename ${DIST_DIR})
    local tarFile=$base.tar
    tar -cf ${tarFile} $THIS_SCRIPT_NAME ${base}/
    echo "Copy/move ${tarFile} to airgapped server."

}


function openHTTPAndTFTPPorts
{
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --permanent --add-port=443/tcp
  firewall-cmd --permanent --add-port=69/udp
  firewall-cmd --reload
}

function setupApache
{
    local htmlDir=/var/www/html
    mkdir -p $htmlDir/rhcos
    mkdir -p $htmlDir/ignition
    echo "Configuring Apache..."

    #creating index file
    cat > /var/www/html/index.html << EOF
<html>
<body>
<a href="./rhcos/">RHCOS binaries</a><br/>
<a href="./ignition/">Ignition files</a><br/>
</html>
</body>
EOF


    echo "Starting and enabling Apache server..."
    systemctl daemon-reload
    systemctl enable httpd
    systemctl restart httpd

    #setting SELinux
    chcon -R -h -t httpd_sys_content_t $htmlDir

    echo "Configuring Apache...done."
}

function prepareTFTPJump
{
  #download boot image
  #https://cloud.redhat.com/blog/how-to-make-a-pxe-boot-menu-to-install-openshift-4.x
  wget https://raw.githubusercontent.com/leoaaraujo/openshift_pxe_boot_menu/main/files/bg-ocp.png -O $DIST_DIR/bg-ocp.png
}


function setupTFTPServerAirgapped
{
    echo "Configuring TFTP server..."

  local webServerFQDN=${WEBSERVER_HOSTNAME}.${DOMAIN}
    #create tftp config
    #create PXE boot menu for openshift
    mkdir -p /usr/share/syslinux/pxelinux.cfg
    cp $DIST_DIR/bg-ocp.png /usr/share/syslinux/
    cat > /usr/share/syslinux/pxelinux.cfg/default << EOF
UI vesamenu.c32
MENU BACKGROUND        bg-ocp.png
MENU COLOR sel         4  #ffffff std
MENU COLOR title       1  #ffffff
TIMEOUT 600
PROMPT 0
MENU TITLE OPENSHIFT 4.x INSTALL PXE MENU
LABEL INSTALL WORKER
  MENU DEFAULT
  KERNEL http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-kernel-x86_64
  APPEND initrd=http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-initramfs.x86_64.img coreos.live.rootfs_url=http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-rootfs.x86_64.img coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://${webServerFQDN}/ignition/worker.ign
LABEL INSTALL MASTER
  KERNEL http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-kernel-x86_64
  APPEND initrd=http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-initramfs.x86_64.img coreos.live.rootfs_url=http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-rootfs.x86_64.img coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://${webServerFQDN}/ignition/master.ign
LABEL INSTALL BOOTSTRAP
  KERNEL http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-kernel-x86_64
  APPEND initrd=http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-initramfs.x86_64.img coreos.live.rootfs_url=http://${webServerFQDN}/rhcos/rhcos-4.8.14-x86_64-live-rootfs.x86_64.img coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://${webServerFQDN}/ignition/bootstrap.ign
EOF

    #disable dns in dnsmasq
    echo port=0 > /etc/dnsmasq.d/dns.conf
    #enable tftp
    echo "enable-tftp" > /etc/dnsmasq.d/tftpd.conf
    #echo "tftp-secure" >> /etc/dnsmasq.d/tftpd.conf
    echo "tftp-root=/usr/share/syslinux" >> /etc/dnsmasq.d/tftpd.conf
    echo "Configuring SELinux..."
    set +e
    semodule -l |grep my-dnsmasq > /dev/null
    local rv=$?
    set -e
    if [ $rv -eq 0 ]; then
        echo "SELinux seems to be configured..."
    else
        semanage fcontext -a -t public_content_t "/usr/share/syslinux/pxelinux.cfg" || true
        semanage fcontext -a -t public_content_t "/usr/share/syslinux/pxelinux.cfg(/.*)?" || true
        restorecon -R -v /usr/share/syslinux/pxelinux.cfg 
        cat > ${OMG_RUNTIME_DIR}/my-dnsmasq.te << EOF
module my-dnsmasq 1.0;

require {
        type public_content_t;
        type admin_home_t;
        type dnsmasq_t;
        class file { getattr open read };
        class dir search;
}

#============= dnsmasq_t ==============

#!!!! This avc is allowed in the current policy
allow dnsmasq_t admin_home_t:file { getattr open read };

#!!!! This avc is allowed in the current policy
allow dnsmasq_t public_content_t:dir search;
allow dnsmasq_t public_content_t:file getattr;

#!!!! This avc is allowed in the current policy
allow dnsmasq_t public_content_t:file { open read };
EOF

        checkmodule -M -m -o ${OMG_RUNTIME_DIR}/my-dnsmasq.mod ${OMG_RUNTIME_DIR}/my-dnsmasq.te
        semodule_package -o ${OMG_RUNTIME_DIR}/my-dnsmasq.pp -m ${OMG_RUNTIME_DIR}/my-dnsmasq.mod
        semodule -i ${OMG_RUNTIME_DIR}/my-dnsmasq.pp 
    fi

    echo "Starting and enabling TFTP server..."
    systemctl daemon-reload
    systemctl enable dnsmasq
    systemctl restart dnsmasq

}

function configureHTTPServer
{
  local htmlDir=/var/www/html
  mkdir -p $htmlDir/rhcos
  mkdir -p $htmlDir/ignition
  mv $DIST_DIR/rhcos/* /var/www/html/rhcos
  setupApache
  setupTFTPServerAirgapped
}

function downloadOpenShiftClient
{
    local __file=$1
    echo "Downloading ${__file}..."
    local __dlurl=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION
    curl $__dlurl/${__file} > ${__file}

    echo "Extracting ${__file} to /usr/local/bin/..."
    tar  -C /usr/local/bin/ -xf ${__file}
    rm -f  ${__file}
    echo "Downloading ${__file}...done."
}

function downloadGrpcurl
{
    echo "Downloading grpcurl..."
    local __client_filename=grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz
    curl -L https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/${__client_filename} > ${__client_filename}
    echo "Extracting grpcurl to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f ${__client_filename}
    echo "Downloading grpcurl...done."
}

function downloadCloudctl
{
    echo "Downloading cloudctl..."
    local __client_filename=cloudctl-linux-amd64.tar.gz
    curl -L https://github.com/IBM/cloud-pak-cli/releases/download/v${CLOUDCTL_VERSION}/${__client_filename} > ${__client_filename}
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f /usr/local/bin/cloudctl
    mv /usr/local/bin/cloudctl* /usr/local/bin/cloudctl
    rm -f ${__client_filename}
    echo "Downloading cloudctl...done."
}

function downloadKubeterminal
{
    echo "Downloading kubeterminal.bin..."
    podman pull docker.io/kazhar/kubeterminal:$KUBETERMINAL_TAG
    podman create -it --name kubeterminal docker.io/kazhar/kubeterminal:$KUBETERMINAL_TAG bash
    podman cp kubeterminal:/kubeterminal kubeterminal.bin
    podman rm -fv kubeterminal
    podman rmi kazhar/kubeterminal:$KUBETERMINAL_TAG
    echo "Copying kubeterminal.bin to /usr/local/bin/..."
    mv kubeterminal.bin /usr/local/bin/
    echo "Downloading kubeterminal.bin...done."
}

function createSSHKey
{
  if [ -f ${SSH_KEY_FILE} ]; then
    echo "SSH key already created."
  else
    echo "Creating new SSH key..."
    ssh-keygen -t ${SSH_TYPE} -N '' -f ${SSH_KEY_FILE}
  fi 
}


function downloadClients
{
  echo "Downloading clients..."
  if [ ! -f "/usr/local/bin/oc" ]; then

    downloadOpenShiftClient openshift-client-linux.tar.gz

    downloadOpenShiftClient openshift-install-linux.tar.gz

    downloadOpenShiftClient opm-linux.tar.gz

    downloadGrpcurl

    downloadCloudctl
    
    downloadKubeterminal

  else
    echo "Clients seem to be already downloaded."
    echo "delete /usr/local/bin/oc to download all clients again."
  fi
  echo "Downloading clients...done."

}

function mirrorOpenShiftImagesToFiles
{
  if [ ! -f "$OCP_PULL_SECRET_FILE" ]; then
    error "Pull secret $OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
  fi

  local imageDir=${DIST_DIR}/ocp-images
    if [ -d "${imageDir}" ]
    then
        echo "Download directory ${imageDir} already exists. Will not download again."
        echo "'rm -rf ${imageDir}' if you want to download images again."
    else
        #does not exist, download
        mkdir -p $imageDir
        echo "Mirroring images to ${imageDir}..."
      local __ocp_release="${OCP_VERSION}-x86_64"
      local __ocp_product_repo='openshift-release-dev'
      local __ocp_release_name="ocp-release"

      oc adm release mirror -a ${OCP_PULL_SECRET_FILE} --from=quay.io/${__ocp_product_repo}/${__ocp_release_name}:${__ocp_release} --to-dir=${imageDir} 2>&1 | tee ${DIST_DIR}/mirror-output.txt
    fi

}

function mirrorOpenShiftImagesToMirrorRegistry
{
    local __registry=${REGISTRY_HOST}
    local __ocp_release="${OCP_VERSION}-x86_64"
    local imageDir=${DIST_DIR}/ocp-images
    echo "Mirroring images to ${__registry}/${OPENSHIFT_REPO}..."
    echo "Logging in to registry ${__registry}..."
    podman login ${__registry} -u $REGISTRY_USER_NAME -p $REGISTRY_USER_PASSWORD
    echo "Creating pull secret..."
    cat ${XDG_RUNTIME_DIR}/containers/auth.json | jq -c . > ${OCP_PULL_SECRET_FILE}
    #command
    echo "Creating mirror cmd..."
    local __ocp_release="${OCP_VERSION}"    
    local mirrorCmd="oc image mirror -a ${OCP_PULL_SECRET_FILE} --max-per-registry=1 --max-registry=1  --from-dir=${imageDir} 'file://openshift/release:${__ocp_release}*' ${__registry}/${OPENSHIFT_REPO}"
    local cdir=$(pwd)
    cd $imageDir
    echo $mirrorCmd | sh
    cd $cdir
}

function prepareOpenShiftInstallAirgapped
{
  echo "Preparing OpenShift install..."
  if [ -d "${OPENSHIFT_INSTALL_DIR}" ]
  then
      echo "Directory ${OPENSHIFT_INSTALL_DIR} exists." 
      echo "Have you already installed OpenShift?" 
      error "Remove ${OPENSHIFT_INSTALL_DIR} and try again."
  fi

  #create install directory
  mkdir -p ${OPENSHIFT_INSTALL_DIR}

  local __pull_secret_json=$(cat $OCP_PULL_SECRET_FILE | jq -c '')

  createSSHKey

  echo "creating install-config.yaml..."
  local __install_cfg_file=${OMG_RUNTIME_DIR}/install-config.yaml
  #create install-config.yaml
  cat > ${__install_cfg_file} << EOF
apiVersion: v1
metadata:
  name: ${CLUSTER_NAME}
baseDomain: ${DOMAIN}
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
  - cidr: ${OPENSHIFT_NODE_NETWORK_CIDR}
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {} 
fips: false
pullSecret: '${__pull_secret_json}'
EOF
  
  #add ssh key to install config file
  echo -n "sshKey: '" >> ${__install_cfg_file} && cat ${SSH_KEY_FILE}.pub | sed "s/$/\'/g" >> ${__install_cfg_file}

  #start airgapped install 
  #add CA certificate, if it exists
  local __distDir=$DIST_DIR-bastion
  local __ca_cert_file=${__distDir}/ca.crt
  if [ -f $__ca_cert_file ]; then
    echo "additionalTrustBundle: |" >> $__install_cfg_file
    cat ${__ca_cert_file} | sed 's/^/\ \ \ \ \ /g' >> $__install_cfg_file
  fi

  #add imagecontentsource in airgapped install
  local __registry=${REGISTRY_HOST}
  cat >> ${__install_cfg_file} << EOF
imageContentSources: 
- mirrors:
  - ${__registry}/${OPENSHIFT_REPO}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${__registry}/${OPENSHIFT_REPO}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

  #end airgapped install 

  #remove empty lines if there are any
  sed -i '/^[[:space:]]*$/d' $__install_cfg_file

  #backup of install-config.yaml
  local timestamp=$(date "+%Y%m%d%H%M%S")
  cp ${__install_cfg_file} ${OPENSHIFT_INSTALL_DIR}/install-config-${timestamp}.yaml

  #copy install-config file to install-directory
  cp $__install_cfg_file $OPENSHIFT_INSTALL_DIR/

  echo "creating manifest files..."
  local __current_dir=$(pwd)
  cd $OPENSHIFT_INSTALL_DIR/
  openshift-install create manifests --dir=./
  if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    #when using  user-provisioned infrastructure installation, master nodes are schedulable
    #make master unschedulable if not using three node cluster
    echo "configuring master nodes unschedulable..."
    sed -i  "s/mastersSchedulable: true/mastersSchedulable: false/g" manifests/cluster-scheduler-02-config.yml
  fi

  echo "creating ignition files..."
  openshift-install create ignition-configs --dir=./
  
  echo "copy ignition files to Apache server..."
  echo "for example"
  local htmlDir=/var/www/html
  echo htmlDir=/var/www/html
  #delete existing ignition files
  echo rm -f $htmlDir/ignition/*ign
  echo chmod 644 *ign
  echo mv *ign $htmlDir/ignition
  #setting SELinux
  echo chcon -R -h -t httpd_sys_content_t $htmlDir/ignition

  cd $__current_dir

  echo "Preparing OpenShift install...done."

}

function ocpCompleteInstall
{
  local __current_dir=$(pwd)
  cd $OPENSHIFT_INSTALL_DIR/
  openshift-install --dir=./ wait-for install-complete 2>&1 | tee ${OMG_RUNTIME_DIR}/install-complete.txt
  cd $__current_dir
}


function getKubeConfig
{
    local __kubeconfig="notfound"
    if [ -d "${__openshift_ipi_install_dir}" ]
    then
      __kubeconfig="${__openshift_ipi_install_dir}/auth/kubeconfig"
    fi

    if [ -d "${OPENSHIFT_INSTALL_DIR}" ]
    then
      __kubeconfig="${OPENSHIFT_INSTALL_DIR}/auth/kubeconfig"
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
  if [ ! -d "${OPENSHIFT_INSTALL_DIR}" ]
  then
      echo "Directory ${OPENSHIFT_INSTALL_DIR} does not exist." 
      error "Have you prepared to install OpenShift?" 
  fi
  local __current_dir=$(pwd)
  #local timestamp=$(date "+%Y%m%d%H%M%S")
  cd $OPENSHIFT_INSTALL_DIR/
  openshift-install --dir=./ wait-for bootstrap-complete --log-level debug 2>&1 | tee ${OMG_RUNTIME_DIR}/bootstrap-complete.txt
  cd $__current_dir
  echo "Waiting for bootstrap...done."
}


function prepareHTTPJumpServer
{
  DIST_DIR=$DIST_DIR-httpd
  downloadRHCOSBinaries
  prepareTFTPJump
  createDistributionPackage
}

function prepareHTTPAirgapped
{
  DIST_DIR=$DIST_DIR-httpd
  openHTTPAndTFTPPorts
  configureHTTPServer
  setupTFTPServerAirgapped  
}

function prepareBastionJumpServer
{
  local certFile=$CERT_DIR/ca.crt
  if [[ ! -f "$certFile" ]]
  then
      error "CA certificate does not exists. Copy CA certificate to $certFile."
  fi

  DIST_DIR=$DIST_DIR-bastion
  downloadClients
  cp -r $CERT_DIR $DIST_DIR/
  mkdir -p $DIST_DIR/bin/
  cp -r /usr/local/bin/* $DIST_DIR/bin/
  mirrorOpenShiftImagesToFiles
  createDistributionPackage
}


function prepareBastionAirgapped
{
  DIST_DIR=$DIST_DIR-bastion
  cp -r $DIST_DIR/bin/* /usr/local/bin/
  
  echo "Adding CA cert as trusted..."
  local __cert_file=$DIST_DIR/ca.crt
  cp ${__cert_file} /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract

  mirrorOpenShiftImagesToMirrorRegistry
  prepareOpenShiftInstallAirgapped
}

function setupOpenShiftInstallFiles
{
  prepareOpenShiftInstallAirgapped
}


function setupHAProxyAirgapped
{
  setsebool -P haproxy_connect_any=1
  firewall-cmd --permanent --add-port=443/tcp
  firewall-cmd --permanent --add-port=6443/tcp
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --permanent --add-port=22623/tcp
  firewall-cmd --reload
}

case "$1" in
  prepare-httpd-tftp-jump)
    prepareHTTPJumpServer
  ;;
  prepare-httpd-tftp-airgapped)
    prepareHTTPAirgapped
  ;;
  setup-haproxy)
    setupHAProxyAirgapped
  ;;
  prepare-bastion-jump)
    prepareBastionJumpServer
  ;;
  prepare-bastion-airgapped)
    prepareBastionAirgapped
  ;;
  setup-openshift-install)
    setupOpenShiftInstallFiles
  ;;
  ocp-complete-bootstrap)
    ocpCompleteBootstrap
  ;;
  ocp-csr)
    ocpGetCSR
  ;;
  ocp-nodes)
    ocpGetNodes
  ;;
  ocp-approve-csr)
    ocpApproveAllCSRs
  ;;
  ocp-cluster-operators)
    ocpGetClusterOperators
  ;;
  ocp-complete-install)
    ocpCompleteInstall
  ;;
  *)
    usage
  ;;
esac

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-) 
