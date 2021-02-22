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
  echo "command:"
  echo "  install-prereqs         - Install prereqs."
  echo "  setup-ntp               - Setup NTP server."
  echo "  setup-apache            - Setup Apache server for RHCOS images and iginition files."
  echo "  setup-dns               - Setup DNS server."
  echo "  setup-dhcp              - Setup DHCP and PXE server."
  echo "  setup-haproxy           - Setup HAProxy server."
  echo "  firewall-open           - Open firewall ports."
  echo "  firewall-close          - Open firewall ports."
  echo "  download-clients        - Download OpenShift clients and KubeTerminal."
  echo "  setup-openshift-install - Setup bastion for OpenShift installation."
  echo ""
  exit 1
}

if [[ "$OCP_PULL_SECRET_FILE" == "" ]]; then
  error "Environment variables are not set."
fi

if [ ! -f "$OCP_PULL_SECRET_FILE" ]; then
  error "Pull secret $OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
fi

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
    *)
        usage
        ;;
esac

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-) 