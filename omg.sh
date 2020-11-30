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

#include some common functions 
. scripts/functions.sh

#check environment variable and exit if not set
#source config.sh
if [[ "$OCP_OMG_SERVER_ROLE" == "" ]]; then
  usageEnv OCP_OMG_SERVER_ROLE
fi

#if no command gives, show usage and exit
if [[ "$1" == "" ]]; then
  echo "Operation is missing."
  usage
fi

set -e 

#prereq packages
__packages="podman jq nmap ntpstat bash-completion httpd-tools curl wget tmux net-tools nfs-utils python3 git"
if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
  #add these packages when in jump server
  __packages="${__packages} yum-utils createrepo libmodulemd modulemd-tools"
fi

if [[ "$OCP_OMG_SERVER_ROLE" == "haproxy" ]]; then
  #only podman needed for haproxy
  __packages="podman"
fi

#global variables
__operation=$1
__script_dir=install

if [[ "${__operation}" == "prereq-install" ]]; then
  prereq_install
fi

#include script components
. scripts/systemctl-svc.sh
. scripts/haproxy.sh
. scripts/firewall.sh
. scripts/boot-services.sh
. scripts/dist-packages.sh
. scripts/mirroring.sh
. scripts/certificates.sh
. scripts/bastion.sh


#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-)
