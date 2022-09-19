if [[ "$OMG_OCP_DOMAIN" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

if [ ! -d "ocp-images" ]; then
    echo "ocp-images directory does not exist."
    exit 1
fi

#registry user and password
#change to correct values
REGISTRY_USER_NAME=admin
REGISTRY_USER_PASSWORD=passw0rd
REGISTRY_SERVER=$OMG_OCP_MIRROR_REGISTRY_HOST_NAME.$OMG_OCP_DOMAIN:$OMG_OCP_MIRROR_REGISTRY_PORT

#repo in mirror registry
OPENSHIFT_REPO=mirror


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

function editImageContentSourcePolicy
{
  local resultDir=$(ls -1tr oc-mirror-workspace/ | grep results | tail -1)
  cat oc-mirror-workspace/$resultDir/imageContentSourcePolicy.yaml |grep "^  - mirr\|^    [-s]" > images.yaml
  #change any docker.io to registry.docker.io
  #this is because mirror plugin validates registry using host.domain.suffix
  sed -i "s/ docker.io/ registry.docker.io/g" images.yaml

}



function mirrorImagesFromFile
{
    echo "Mirroring images..."

    oc mirror --from=./ocp-images/ docker://$REGISTRY_SERVER/$OPENSHIFT_REPO

    editImageContentSourcePolicy

    echo "Mirroring images...done."
}


loginToRegistry
mirrorImagesFromFile
