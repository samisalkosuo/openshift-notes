#omg Native tool

set -e 

#include files
source scripts/functions.sh

function usage
{
  echo "OpenShift installer helper for airgapped OpenShift UPI installations."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands (jump):"
  echo ""
  echo "  install-prereqs         - Install prereq packages using dnf."
  echo "  download-clients        - Download clients (oc, openshift-install, coredns, etc.)."
  echo "  download-ocp-images     - Download OpenShift images to directory."
  echo "  create-dist-package     - Create tar-package for distribution."
  echo ""
  echo "Commands (bastion):"
  echo "  create-local-repo       - Create local dnf repository."
  echo "  install-prereqs-bastion - Install prereqs from local repository."
  echo "  create-mirror-registry  - Create mirror registry using registry-image and self-signed certificate."
  echo "  upload-ocp-images       - Upload OpenShift images to mirror registry."
  echo "  create-lb-dist-package  - Create tar-package for load balancer distribution."
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

case "$1" in
    install-prereqs)
        installPrereqs
        installPrereqsForAirgapped
    ;;
    install-prereqs-bastion)
        installPrereqsBastion
        copyBinariesToUsrLocalBin
        loadContainerImages
        copyRHCOSBinaries
    ;;
    download-clients)
        downloadClients
    ;;
    download-rhcos)
        downloadRHCOSBinaries $__dist_dir/rhcos
        ;;
    download-containers)
        downloadContainers
        ;;
    download-ocp-images)
        mirrorOpenShiftImagesToFiles
        ;;
    create-dist-package)
        createDistributionPackage
        ;;
    create-local-repo)
        createLocalDNFRepository
        ;;
    create-mirror-registry)
        createMirrorRegistry
        ;;
    upload-ocp-images)
        mirrorOpenShiftImagesToMirrorRegistry
        ;;
    create-lb-dist-package)
        createLoadbalancerDistributionPackage
        ;;
    *)
        usage
        ;;
esac

#FYI, script name "omg" comes from "(O)penshift install (M)ana(G)er tool" :-) 