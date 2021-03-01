#omg Native tool

set -e 

#include files
. scripts/functions.sh

function usage
{
  echo "OpenShift installer helper."
  echo ""
  echo $"Usage: $0 <command>"
  echo ""
  echo "command (online):"
  echo "  install-prereqs         - Install prereqs."
  echo "  download-clients        - Download OpenShift clients and KubeTerminal."
  echo ""
  echo "command (bastion, online/airgapped):"
  echo "  setup-ntp               - Setup NTP server."
  echo "  setup-apache            - Setup Apache server for RHCOS images and iginition files."
  echo "  setup-dns               - Setup DNS server."
  echo "  setup-dhcp              - Setup DHCP and PXE server."
  echo "  setup-openshift-install - Setup bastion for OpenShift installation."
  echo ""
  echo "command (bastion/haproxy, online/airgapped):"
  echo "  setup-haproxy           - Setup HAProxy server."
  echo ""
  echo "command (jump-server, online):"
  echo "  create-certs            - Create CA-cert and certificate for registry."
  echo "  create-mirror-registry  - Create mirror registry."
  echo "  do-mirroring            - Mirror OpenShift images to mirror-registry."
  echo "  create-dist-package     - Create dist-package to be transferred to airgapped bastion."
  echo "  create-update-package   - Create OpenShift update package to be transferred to airgapped bastion."
  echo ""
  echo "command (bastion, airgapped):"
  echo "  prepare-bastion         - Prepare bastion for OpenShift installation."
  echo "  create-haproxy-dist-pkg - Create dist-package to be transferred to haproxy-server."
  echo "  upload-update-images    - Upload OpenShift update images to mirror registry."
  echo ""
  echo "command (all):"
  echo "  firewall-open           - Open firewall ports."
  echo "  firewall-close          - Open firewall ports."
  echo ""
  exit 1
}

if [[ "$OCP_PULL_SECRET_FILE" == "" ]]; then
  error "Environment variables are not set."
fi

if [ ! -f "$OCP_PULL_SECRET_FILE" ]; then
  error "Pull secret $OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
fi

#prereq packages, these are installed and (if using airgapped environment) transferred to airgapped bastion
#this variable is used in functions
#packages include required packages and not-so required useful tools
__prereq_packages="podman jq nmap ntpstat bash-completion httpd-tools curl wget tcpdump tmux net-tools nfs-utils python3 git openldap openldap-clients openldap-devel chrony httpd bind bind-utils dnsmasq dhcp-server dhcp-client haproxy syslinux container*"
__prereq_packages_jump="yum-utils createrepo libmodulemd modulemd-tools"

case "$1" in
    install-prereqs)
        installPrereqs
        ;;
    setup-ntp)
        configureNTPServer
        ;;
    setup-apache)
        configureApache
        ;;
    setup-dns)
        configureDNS
        ;;
    setup-dhcp)
        configureDHCPandPXE
        ;;
    setup-haproxy)
        configureHAProxy
        ;;
    firewall-open)
        openPorts
        ;;
    firewall-close)
        closePorts
        ;;
    download-clients)
        downloadClients
        ;;
    setup-openshift-install)
        setupOpenShiftInstall
        ;;
    create-certs)
        createCACert $OCP_DOMAIN
        createRegistryCert $OCP_DOMAIN
        ;;
    create-mirror-registry)
        createMirrorRegistry
        ;;
    do-mirroring)
        createPullSecret
        mirrorOpenShiftImages
        ;;
    create-dist-package)
        createOfflineRepository
        packageFilesForBastion
        ;;
    prepare-bastion)
        prepareAirgappedBastion
        ;;
    create-haproxy-dist-pkg)
        createHAProxyDistPackage
        ;;
    create-update-package)
        downloadImagesAndCreatePackage
        ;;
    upload-update-images)
        uploadUpdateImages
        ;;
    *)
        usage
        ;;
esac

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-) 