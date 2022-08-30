#!/bin/sh

#download OCP images

if [[ "$OMG_OCP_PULL_SECRET_FILE" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

if [ ! -f "$OMG_OCP_PULL_SECRET_FILE" ]; then
  echo "Pull secret $OMG_OCP_PULL_SECRET_FILE does not exist. Download it from Red Hat."
  exit 1
fi

set -e

DOWNLOAD_DIR=ocp-images

#variable for mirroring for airgapped environment
#do not change, unless explicitly instructed 
__ocp_release="${OMG_OCP_VERSION}-x86_64"
__ocp_local_repository='ocp/openshift4'
__ocp_product_repo='openshift-release-dev'
__ocp_release_name="ocp-release"

function ocpMirrorImagesToFiles
{
  echo "Mirroring OCP images..."

  if [ -d "${DOWNLOAD_DIR}" ]
  then
    echo "Download directory ${DOWNLOAD_DIR} already exists. Will not download again."
    echo "'rm -rf ${DOWNLOAD_DIR}' if you want to download images again."
  else
    mkdir -p $DOWNLOAD_DIR

    oc adm -a ${OMG_OCP_PULL_SECRET_FILE} release mirror --from=quay.io/${__ocp_product_repo}/${__ocp_release_name}:${__ocp_release} --to-dir=${DOWNLOAD_DIR} 2>&1 | tee $DOWNLOAD_DIR/mirror-output.txt
  fi

  echo "Mirroring OCP images...done."
}

function packageImages
{
  echo "Creating OCP images tar-file..."
  tar -cf $DOWNLOAD_DIR.tar $DOWNLOAD_DIR
  echo "Creating OCP images tar-file...done."
}

ocpMirrorImagesToFiles
#packageImages
