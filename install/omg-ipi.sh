#omg Native tool

set -e 

#include files
. scripts/functions.sh

function usage
{
  echo "OpenShift installer helper for online OpenShift IPI installations."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo ""
  echo "  install-prereqs        - Install prereq packages using dnf."
  echo "  download-clients       - Download clients (oc, openshift-install, coredns, etc.)."
  echo "  setup-ntp              - Setup NTP server."
  echo "  setup-dns              - Setup DNS server."
  echo "  setup-dhcp             - Setup DHCP/PXE server."
  echo "  setup-lb               - Setup gobetween-loadbalancer."
  echo "  create-lb-dist-package - Create tar-package for load balancer distribution."
  echo "  firewall               - Open/close firewall ports."
  echo "  extract-certs          - Extract and trust VCenter certificates."
  echo "  create                 - Create OpenShift IPI cluster."
  echo "  destroy                - Destroy created cluster."
  echo "  ocp-cluster-operators  - Watch status of cluster operators."
  echo ""
  exit 1
}

if [[ "$OCP_PULL_SECRET_FILE" == "" ]]; then
  error "Environment variables are not set."
fi

if [ ! -f "$OCP_PULL_SECRET_FILE" ]; then
  error "Pull secret $OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
fi

#call functions
#note 'shift' command moves ARGS to the left 
#=> for example removes govc param and sends remaining args as options to command

case "$1" in
    install-prereqs)
        installPrereqs
    ;;
    download-clients)
        downloadClients
    ;;
    setup-ntp)
        setupNTPServer
    ;;
    setup-dns)
        setupDNS
    ;;
    setup-dhcp)
        setupDHCPOnly
    ;;
    setup-lb)
        setupLoadBalancer
        ;;
    create-lb-dist-package)
        createLoadbalancerDistributionPackage
        ;;
    extract-certs)
        extractVCenterCerts
        ;;
    create)
        ocpIPIInstall
        ;;
    destroy)
        ocpIPIDestroy
        ;;
    ocp-cluster-operators)
        ocpGetClusterOperators
        ;;
    firewall)
        shift
        firewallCommand $*
        ;;
    *)
        usage
        ;;
esac

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-) 