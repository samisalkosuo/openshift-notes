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
  echo "install prereqs and clients (online, bastion and jump-server):"
  echo "  install-prereqs          - Install prereqs."
  echo "  download-clients         - Download OpenShift clients and KubeTerminal."
  echo ""
  echo "setup services (bastion, online/airgapped):"
  echo "  setup-ntp                - Setup NTP server."
  echo "  setup-apache             - Setup Apache server for RHCOS images and iginition files."
  echo "  setup-dns                - Setup DNS server."
  echo "  setup-dhcp               - Setup DHCP and PXE server."
  echo ""
  echo "setup OpenShift installation (bastion, online/airgapped):"
  echo "  setup-openshift-install  - Setup bastion for OpenShift installation."
  echo ""
  echo "setup services (bastion/haproxy, online/airgapped):"
  echo "  setup-haproxy            - Setup HAProxy server."
  echo ""
  echo "prepare for airgapped install (jump-server, online):"
  echo "  create-certs             - Create CA-cert and certificate for registry."
  echo "  create-mirror-registry   - Create mirror registry."
  echo "  do-mirroring             - Mirror OpenShift images to mirror-registry."
  echo "  download-ocp-images      - Mirror OpenShift images to files."
  echo "  create-dist-package      - Create dist-package to be transferred to airgapped bastion."
  echo ""
  echo "install airgapped OpenShift (bastion, airgapped):"
  echo "  prepare-bastion          - Prepare bastion for OpenShift installation."
  echo "  create-local-repository  - Create local repository for prereq packages."
  echo "  create-haproxy-dist-pkg  - Create dist-package to be transferred to haproxy-server."
  echo ""
  echo "update airgapped OpenShift (jump-server/bastion, online/airgapped):"
  echo "  create-update-package    - Create OpenShift update package to be transferred to airgapped bastion (online jump-server)."
  echo "  upload-update-images     - Upload OpenShift update images to mirror registry (airgapped bastion)."
  echo ""
  echo "operator catalog for airgapped installation (jump-server/bastion, online/airgapped):"
  echo "  olm-index                - Print index image used (online jump-server)."
  echo "  olm-list                 - List operators in index (online jump-server)."
  echo "  olm-prune-index          - Prune index (online jump-server)."
  echo "  olm-download-images      - Download images based on index (online jump-server)."
  echo "  olm-upload-images        - Upload mirrored images to registry (bastion airgapped)."
  echo ""
  echo "firewall (all):"
  echo "  firewall-open            - Open firewall ports."
  echo "  firewall-close           - Open firewall ports."
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
    create-local-repository)
        createOfflineRepository
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
    olm-index)
        olm_printOperatorIndexImage
        ;;
    olm-list)
        olm_listOperators
        ;;
    *)
        usage
        ;;
esac

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-) 