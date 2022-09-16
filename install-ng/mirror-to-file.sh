#mirror OCP and other images using oc-mirror command
#see
#https://docs.openshift.com/container-platform/4.10/installing/disconnected_install/installing-mirroring-disconnected.html

if [[ "$OMG_OCP_VERSION" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

if [ ! -f "$OMG_OCP_PULL_SECRET_FILE" ]; then
  echo "Pull secret $OMG_OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
  exit 1
fi

echo "Have you configured imageset-config.yaml file to match OpenShift $OMG_OCP_VERSION and added operators and images for mirroring (yes/no)?"
read answer
if [[ "$answer" != "yes" ]]; then
  echo "Open imageset-config.yaml and configure mirroring."
  exit 1
fi

DOWNLOAD_DIR=ocp-images

set -e

function mirrorImages 
{

    echo "Mirroring images..."

    local localDir=$(pwd)

    oc mirror --config=./imageset-config.yaml file://$localDir/$DOWNLOAD_DIR

    echo "Mirroring images...done."
    echo ""
    echo "Copy/move $DOWNLOAD_DIR/mirror_seq*.tar file(s) to airgapped environment."
}

function packageImages
{
   echo "Creating OCP images tar-file..."
   tar -cf $DOWNLOAD_DIR.tar $DOWNLOAD_DIR
   echo "Creating OCP images tar-file...done."
}

mirrorImages

#packageImages
