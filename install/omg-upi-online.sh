#omg Native tool

set -e 

#include files
. scripts/functions.sh

function usage
{
  echo "OpenShift installer helper for online OpenShift UPI installations."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo ""
  echo "  install-prereqs        - Install prereq packages using dnf."
  echo "  download-clients       - Download clients (oc, openshift-install, coredns, etc.)."
  echo "  download-rhcos         - Download RHCOS binaries to /var/www/html/rhcos directory."
  echo "  setup-ntp              - Setup NTP server."
  echo "  setup-dns              - Setup DNS server."
  echo "  setup-apache           - Setup Apache server for RHCOS and ignition files."
  echo "  setup-dhcp             - Setup DHCP/PXE server."
  echo "  setup-lb               - Setup gobetween-loadbalancer."
  echo "  create-lb-dist-package - Create tar-package for load balancer distribution."
  echo "  govc                   - Helper command for govc to manage VMWare VMs. See '$0 govc' for commands/options."
  echo "  firewall               - Open/close firewall ports."
  echo "  ocp-prepare-install    - Prepare OpenShift installation. Creates install-config.yaml and ignition files."
  echo "  ocp-start-install      - Print OpenShift install checklist."
  echo "  ocp-complete-bootstrap - Wait for bootstrap to be complete."
  echo "  ocp-csr                - Watch CSRs."
  echo "  ocp-approve-csr        - Approve all CSRs."
  echo "  ocp-nodes              - Watch nodes."
  echo "  ocp-cluster-operators  - Watch status of cluster operators."
  echo "  ocp-complete-install   - Complete OpenShift installation."
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
    download-rhcos)
        downloadRHCOSBinaries
    ;;
    setup-ntp)
        setupNTPServer
    ;;
    setup-dns)
        setupDNS
    ;;
    setup-apache)
        setupApache
    ;;
    setup-dhcp)
        setupDHCPandPXE
    ;;
    setup-lb)
        setupLoadBalancer
    ;;
    create-lb-dist-package)
        createLoadbalancerDistributionPackage
        ;;
    ocp-prepare-install)
        ocpPrepareInstall
        ;;
    ocp-start-install)
        ocpStartInstall
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
    govc)
        shift
        govcCommand $*
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