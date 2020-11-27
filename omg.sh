#!/bin/bash

#this script, and others, help to install OpenShift and supporting services

function usage
{
  echo "Usage: $0 <OPERATION>"
  echo "  <OPERATION> is one of:"
  echo "    prereq-install               - installs prereq packages"
  echo "    create-ca-cert               - create CA certificate"
  echo "    create-registry-cert         - create registry certificate"
  echo "    create-mirror-image-registry - create mirror image registry"
  echo "    do-mirroring                 - mirror images from Red Hat"
  echo "    create-ntp-server            - create NTP server image"
  echo "    create-apache-rhcos-server   - create Apache server image for RHCOS binaries"
  echo "    create-dns-server            - create DNS server image"
  echo "    create-dhcp-pxe-server       - create DHCP/PXE server image"
  echo "    create-haproxy-server        - create HAProxy server image"
  echo "    create-haproxy-server-wob    - create HAProxy server image without bootstrap"
  echo "    get-kubeterminal             - download KubeTerminal tool"
  echo "    prepare-bastion              - prepare bastion from dist packages"
  echo "    svc-start                    - start systemd-services"
  echo "    svc-stop                     - stop systemd-services"
  echo "    svc-enable                   - enable systemd-services"
  echo "    svc-disable                  - disable systemd-services"
  echo "    svc-status                   - show status of systemd-services"
  echo "    prepare-haproxy              - prepare haproxy from dist packages"  
  echo "    firewall-open                - open firewall for NTP, DNS, DHCP, TFTP"
  echo "    firewall-close               - close firewall for NTP, DNS, DHCP, TFTP"
  echo "    firewall-open-haproxy        - open firewall for HTTP, HTTPS and OpenShift API"
  echo "    firewall-close-haproxy       - close firewall for HTTP, HTTPS and OpenShift API"
  echo "    create-dist-packages         - create packages for distribution to bastion"
  exit 1
}

function usageEnv
{
  echo "$1 env variable missing."
  exit 1
}

if [[ "$OCP_OMG_SERVER_ROLE" == "" ]]; then
  usageEnv OCP_OMG_SERVER_ROLE
fi

set -e 

#prereq packages
__packages="podman jq nmap ntpstat bash-completion httpd-tools curl wget tmux net-tools nfs-utils python3 git"
if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
  #add packages when in jump server
  __packages="${__packages} yum-utils createrepo libmodulemd modulemd-tools"
fi

if [[ "$OCP_OMG_SERVER_ROLE" == "haproxy" ]]; then
  #only podman needed for haproxy
  __packages="podman"
fi


if [[ "$1" == "" ]]; then
  echo "Operation is missing."
  usage
fi

__operation=$1
__script_dir=install

function check_role
{
  local rv=1
  #check whether or not operation is permitted in server
  local roles=$1
  for role in $roles
  do
    if [[ "$role" == "${OCP_OMG_SERVER_ROLE}" ]]; then
      #echo "Operation is allowed in ${OCP_OMG_SERVER_ROLE}."
      rv="${rv}0"
    fi
  done

  set +e
  #if rv does not include 0, then operation is not allowed
  echo $rv |grep 0 &> /dev/null
  if [[ $? != 0 ]]; then
    echo "ERROR: Operation not allowed in current OCP_OMG_SERVER_ROLE=${OCP_OMG_SERVER_ROLE}."
    exit 3
  fi
  set -e
}

if [[ "${__operation}" == "get-kubeterminal" ]]; then
  echo "downloading KubeTerminal..."
  podman create -it --name kubeterminal kazhar/kubeterminal bash
  podman cp kubeterminal:/kubeterminal kubeterminal.bin
  podman rm -fv kubeterminal
  podman rmi kazhar/kubeterminal
  echo "downloading KubeTerminal...done."

fi

if [[ "${__operation}" == "create-haproxy-server-wob" ]]; then
  echo "creating HAProxy server image without bootstrap..."
  cd ${__script_dir}/haproxy
  sh create_haproxy_server.sh nobootstrap
  echo "creating HAProxy server image without bootstrap...done."

fi

if [[ "${__operation}" == "create-haproxy-server" ]]; then
  echo "creating HAProxy server image..."
  cd ${__script_dir}/haproxy
  sh create_haproxy_server.sh
  echo "creating HAProxy server image...done."
fi


if [[ "${__operation}" == "create-dhcp-pxe-server" ]]; then
  echo "creating DHCP/PXE server images..."
  cd ${__script_dir}/boot-services
  sh create_dhcp_pxe_image.sh
  echo "creating DHCP/PXE server images...done."
fi

if [[ "${__operation}" == "create-dns-server" ]]; then
  echo "creating DNS server images..."
  cd ${__script_dir}/boot-services
  sh create_dns_image.sh
  echo "creating DNS server images...done."
fi

if [[ "${__operation}" == "create-apache-rhcos-server" ]]; then
  echo "creating Apache for RHCOS images..."
  cd ${__script_dir}/boot-services
  sh create_apache_image.sh
  echo "creating Apache for RHCOS images...done."
fi

if [[ "${__operation}" == "firewall-close" ]]; then
  # NTP
  firewall-cmd --remove-port=123/udp
  #DNS
  firewall-cmd --remove-port=53/udp --remove-port=53/tcp
  #DHCP/TFTP
  firewall-cmd --remove-port=67/udp --remove-port=69/udp

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-open" ]]; then
  check_role "jump bastion"
  
  #NTP
  firewall-cmd --add-port=123/udp
  #DNS
  firewall-cmd --add-port=53/udp --add-port=53/tcp
  #DHCP/TFTP
  firewall-cmd --add-port=67/udp --add-port=69/udp

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-open-haproxy" ]]; then
  check_role haproxy
  #HTTP/HTTPS
  firewall-cmd --add-port=80/tcp --add-port=443/tcp 
  #OpenShift API
  firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-close-haproxy" ]]; then
  check_role haproxy
  #HTTP/HTTPS
  firewall-cmd --remove-port=80/tcp --remove-port=443/tcp 
  #OpenShift API
  firewall-cmd --remove-port=6443/tcp --remove-port=22623/tcp 

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi


if [[ "${__operation}" == "create-ntp-server" ]]; then
  echo "creating NTP server image..."
  cd ${__script_dir}/ntp-server
  sh create_ntp_server_image.sh
  echo "creating NTP server image...done."
fi

if [[ "${__operation}" == "do-mirroring" ]]; then
  echo "doing mirroring..."

  if [ ! -f "pull-secret.json" ]; then
      echo "ERROR: pull-secret.json does not exist."
      echo "get it from Red Hat and copy it to this directory."
      exit 2
  fi
  cp pull-secret.json ${__script_dir}/mirroring
  cd ${__script_dir}/mirroring
  echo "downloading oc-client.."
  sh download_client.sh
  echo "creating pull secrets..."
  sh create_pull_secrets.sh
  echo "mirroring images.."
  sh mirror.sh
  echo "downloading openshift-install.."
  sh create_install_files.sh ../certificates/CA_$OCP_DOMAIN.crt
  echo "doing mirroring...done."

fi

if [[ "${__operation}" == "create-mirror-image-registry" ]]; then
  echo "creating mirror image registry..."
  cd ${__script_dir}/registry
  echo "pulling registry image..."
  podman pull docker.io/library/registry:2  
  sh create_registry.sh ../certificates/domain.crt ../certificates/domain.key
  echo "creating mirror image registry...done."
fi

if [[ "${__operation}" == "create-registry-cert" ]]; then
  echo "creating registry cert..."
  cd ${__script_dir}/certificates
  sh create_registry_cert.sh
  echo "creating registry cert...done."
fi

if [[ "${__operation}" == "create-ca-cert" ]]; then
  echo "creating CA cert..."
  cd ${__script_dir}/certificates
  sh create_ca_cert.sh
  echo "creating CA cert...done."
fi

function prereq_install
{
  if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
    echo "enabling Extra Packages for Enterprise Linux..."
    #see https://fedoraproject.org/wiki/EPEL
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    __enable_epel_testing="--enablerepo=epel-testing"
  fi
  echo "installing packages...."
  yum -y ${__enable_epel_testing} install $__packages 

  if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
    echo "creating alpine-base image..."
    podman build -t alpine-base ./install/alpine-base
    echo "alpine-base image created"
  fi
  echo "prereq-install done."
}

if [[ "${__operation}" == "prereq-install" ]]; then
  prereq_install
fi

function serviceOperation
{
  local op=$1
  local svc=$2  
  set +e
  ls /etc/systemd/system/${svc}* &> /dev/null
  if [ $? -eq 0 ];  then
    #service exists, do operation
    echo "$op $svc service..."
    local __options=""
    if [[ "$op" == "status" ]]; then
      __options=--no-pager
    fi

    systemctl $__options $op $svc
  else
    echo "service $svc does not exist"
  fi
  set -e
}

function doServiceOperation
{
  local __systemctlOperation=$1
  local __role=jump_and_bastion

  if [[ "$OCP_OMG_SERVER_ROLE" == "haproxy" ]]; then
    __role=haproxy
  fi

  if [[ "$__role" == "jump_and_bastion" ]]; then
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_APACHE_RHCOS
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_APACHE_IGNITION
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_MIRROR_REGISTRY
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_NTP_SERVER
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_DNS_SERVER
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_DHCPPXE_SERVER
  fi
  
  if [[ "$__role" == "haproxy" ]]; then
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_HAPROXY_SERVER
  fi

}

if [[ "${__operation}" == "svc-start" ]]; then
  doServiceOperation start
fi

if [[ "${__operation}" == "svc-stop" ]]; then
  doServiceOperation stop
fi

if [[ "${__operation}" == "svc-enable" ]]; then
  doServiceOperation enable
fi

if [[ "${__operation}" == "svc-disable" ]]; then
  doServiceOperation disable
fi

if [[ "${__operation}" == "svc-status" ]]; then
  doServiceOperation status
fi


if [[ "${__operation}" == "prepare-bastion" ]]; then
  check_role bastion 

  if [[ "$OCP_INSTALL_USER" == "" ]]; then
    usageEnv OCP_INSTALL_USER
  fi
  if [[ "$OCP_SERVICE_NAME_APACHE_IGNITION" == "" ]]; then
    usageEnv OCP_SERVICE_NAME_APACHE_IGNITION
  fi
  if [[ "$OCP_APACHE_IGNITION_PORT" == "" ]]; then
    usageEnv OCP_APACHE_IGNITION_PORT
  fi
  
  echo "preparing bastion..."  
  echo "creating local repo..."
  __repodir=$(pwd)/dist/local_repository
  __repofile=/etc/yum.repos.d/local2.repo
  cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF
  prereq_install
  echo "extracting scripts..."
  tar -xf dist/scripts.tgz -C .
  echo "adding CA cert as trusted..."
  __ca_file_name=CA_${OCP_DOMAIN}
  cp ${__script_dir}/certificates/${__ca_file_name}.crt /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract
  echo "loading container images..."
  ls -1 dist/img_* |awk '{print "podman load -i " $1}' |sh
  echo "copying binaries to /usr/local/bin..."
  cp dist/kubectl dist/kubeterminal.bin dist/oc ${__script_dir}/mirroring/openshift-install /usr/local/bin/
  echo "copying systemctl services to /etc/systemd/system/..."
  cp dist/*.service /etc/systemd/system/
  echo "extracting mirror registry..."
  tar -xf mirror-registry.tar -C /
  echo "creating ocp-user..."
  useradd ${OCP_INSTALL_USER}
  echo "copying install-files to ocp-users install-directory..."
  mkdir -p /home/${OCP_INSTALL_USER}/install
  cp ${__script_dir}/mirroring/install-config.yaml ${__script_dir}/mirroring/mirror-output.txt ${__script_dir}/mirroring/*json /home/${OCP_INSTALL_USER}/install/
  chown -R ${OCP_INSTALL_USER}:${OCP_INSTALL_USER} /home/${OCP_INSTALL_USER}/install
  echo "creating ${OCP_INSTALL_USER}-user ssh key..."
  su - ${OCP_INSTALL_USER} -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
  echo "adding ${OCP_INSTALL_USER}-user ssh key to install-config.yaml..."
  su - ${OCP_INSTALL_USER} -c "echo -n \"sshKey: '\" >> install/install-config.yaml && cat ~/.ssh/id_rsa.pub | sed \"s/$/\'/g\" >> install/install-config.yaml"
  echo "backing up install-config.yaml..."
  su - ${OCP_INSTALL_USER} -c "cp install/install-config.yaml ~/install-config.yaml.backup"
  echo "creating manifest files..."
  su - ${OCP_INSTALL_USER} -c "cd install && openshift-install create manifests --dir=./"
  #when using airgapped user-provisioned infrastructure installation, master nodes are schedulable
  echo "configuring master nodes unschedulable..."
  su - ocp -c  "sed -i  \"s/mastersSchedulable: true/mastersSchedulable: false/g\" install/manifests/cluster-scheduler-02-config.yml"
  echo "creating ignition files..."
  su - ${OCP_INSTALL_USER} -c "cd install && openshift-install create ignition-configs --dir=./"
  echo "creating Apache server for ignition files..."
  __ign_dir=${__script_dir}/boot-services/ignition/
  cp /home/${OCP_INSTALL_USER}/install/*ign ${__ign_dir}
  chmod 644 ${__ign_dir}/*ign
  podman build -t ${OCP_SERVICE_NAME_APACHE_IGNITION} ${__ign_dir}
  __ign_service_file=${__ign_dir}/${OCP_SERVICE_NAME_APACHE_IGNITION}.service
  cp ${__ign_dir}/apache-ignition.service.template ${__ign_service_file}
  sed -i s/%SERVICE_NAME%/${OCP_SERVICE_NAME_APACHE_IGNITION}/g ${__ign_service_file}
  sed -i s/%PORT%/${OCP_APACHE_IGNITION_PORT}/g ${__ign_service_file}
  cp ${__ign_service_file} /etc/systemd/system/
  systemctl daemon-reload
  echo "starting Apache server for ignition files..."
  systemctl start ${OCP_SERVICE_NAME_APACHE_IGNITION}
  #sleep to allow server to start
  sleep 3
  echo "testing ignition file server..."
  curl http://${OCP_APACHE_IGNITION_HOST}:${OCP_APACHE_IGNITION_PORT}/
  echo "preparing bastion... done."

fi

if [[ "${__operation}" == "prepare-haproxy" ]]; then
  check_role haproxy
  echo "creating local repo..."
  __repodir=$(pwd)/dist/local_repository
  __repofile=/etc/yum.repos.d/local2.repo
  cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF
  echo "preparing haproxy..."
  prereq_install
  echo "loading container images..."
  #load images less than ~35MB, assumption is that haproxy is less than that
  ls -l dist/img_* | awk -v MAX=35870976 '/^-/ && $5 <= MAX { print $NF }' |awk '{print "podman load -i " $1}' |sh
  #ls -1 dist/img_* |awk '{print "podman load -i " $1}' |sh
  echo "extracting scripts..."
  tar -xf dist/scripts.tgz ${__script_dir}/haproxy
  echo "copying systemctl services to /etc/systemd/system/..."
  cp dist/${OCP_SERVICE_NAME_HAPROXY_SERVER}.service /etc/systemd/system/
  echo "start/stop haproxy:"
  echo "  systemctl start ${OCP_SERVICE_NAME_HAPROXY_SERVER}"
  echo "  systemctl stop ${OCP_SERVICE_NAME_HAPROXY_SERVER}"
  echo "create new haproxy image:"
  echo "  <configure IP addresses in config.sh>"
  echo "  sh omg.sh <create-haproxy-server | create-haproxy-server-wob>"

fi

if [[ "${__operation}" == "create-dist-packages" ]]; then
  echo "creating distribution files for bastion..."

  __dist_dir=dist
  __repodir=${__dist_dir}/local_repository
  mkdir -p $__repodir
  
  echo "downloading packages..."
  dnf --enablerepo=epel-testing --alldeps download --downloaddir $__repodir --resolve  $__packages

  echo "creating repository..."
  __current_dir=$(pwd)
  cd $__repodir
  createrepo_c .
  repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
  createrepo_mod .
  cd $__current_dir

  echo "saving container images..."
  podman images |grep -v "none\|TAG" |awk -v dir="${__dist_dir}" '{print "podman save -o " dir "/img_"  $3".tar " $1 ":" $2}' |sh

  echo "copying service files..."
  function copySvcFile
  {
    cp /etc/systemd/system/${1}.service ${__dist_dir}/
  }
  copySvcFile ${OCP_SERVICE_NAME_APACHE_RHCOS}
  copySvcFile ${OCP_SERVICE_NAME_MIRROR_REGISTRY}
  copySvcFile ${OCP_SERVICE_NAME_NTP_SERVER}
  copySvcFile ${OCP_SERVICE_NAME_DNS_SERVER}
  copySvcFile ${OCP_SERVICE_NAME_DHCPPXE_SERVER}
  copySvcFile ${OCP_SERVICE_NAME_HAPROXY_SERVER}

  echo "copying oc and kubectl..."
  cp /usr/local/bin/oc ${__dist_dir}/
  cp /usr/local/bin/kubectl ${__dist_dir}/

  echo "downloading kubeterminal..."
  podman create -it --name kubeterminal kazhar/kubeterminal bash
  podman cp kubeterminal:/kubeterminal ${__dist_dir}/kubeterminal.bin
  podman rm -fv kubeterminal
  podman rmi kazhar/kubeterminal

  echo "packaging scripts..."  
  tar -czf ${__dist_dir}/scripts.tgz ${__script_dir}/boot-services/ ${__script_dir}/certificates/ ${__script_dir}/haproxy/ ${__script_dir}/ntp-server/ ${__script_dir}/mirroring/ ${__script_dir}/registry/
  echo "creating tar..."
  tar -cf ${__dist_dir}.tar ${__dist_dir}/
  tar -rf ${__dist_dir}.tar *sh *adoc ${__script_dir}/*adoc
  echo "packaging mirror registry..."
  tar -cf mirror-registry.tar $OCP_MIRROR_REGISTRY_DIRECTORY

  echo "packaging done."
  echo "copy/move following files to bastion server:"
  echo "  ${__dist_dir}.tar"
  echo "  mirror-registry.tar"
fi

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-)
