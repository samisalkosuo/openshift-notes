#!/bin/sh

#download OCP images

if [[ "$OMG_OCP_DOMAIN" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

# if [ ! -f "ocp-images.tar" ]; then
#     echo "ocp-images.tar does not exist."
#     echo "Download OpenShift images before packaging them."
#     exit 1
# fi

#registry user and password
#change to correct values
REGISTRY_USER_NAME=admin
REGISTRY_USER_PASSWORD=passw0rd
REGISTRY_SERVER=$OMG_OCP_MIRROR_REGISTRY_HOST_NAME.$OMG_OCP_DOMAIN:$OMG_OCP_MIRROR_REGISTRY_PORT

#repo in mirror registry
OPENSHIFT_REPO=openshift/release

set -e

if [ ! -d "ocp-images" ]; then
  echo "ocp-images directory does not exist."
  exit 1
fi

function loginToRegistry
{
  podman login -u $REGISTRY_USER_NAME -p $REGISTRY_USER_PASSWORD $REGISTRY_SERVER
  
  #if registry port is 443 login without port
  #so authentication file includes authentication to registry server without port
  if [[ "$OMG_OCP_MIRROR_REGISTRY_PORT" == "443" ]]; then
    podman login -u $REGISTRY_USER_NAME -p $REGISTRY_USER_PASSWORD $OMG_OCP_MIRROR_REGISTRY_HOST_NAME.$OMG_OCP_DOMAIN
  fi

  cp $XDG_RUNTIME_DIR/containers/auth.json $OMG_OCP_PULL_SECRET_FILE
  
}

function ocpMirrorImagesToRegistry
{
  echo "Mirroring OCP images..."

  local __updateImage=$(cat ocp-images/mirror-output.txt  |grep "Update image" |awk '{print $3}')

  local mirrorCmd="oc image mirror -a $OMG_OCP_PULL_SECRET_FILE --max-per-registry=1 --max-registry=1  --from-dir=ocp-images 'file://openshift/release:${OMG_OCP_VERSION}*' $REGISTRY_SERVER/$OPENSHIFT_REPO"

  echo $mirrorCmd | sh 
  
  echo "Mirroring OCP images...done."
}

loginToRegistry
ocpMirrorImagesToRegistry
