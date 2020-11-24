#!/bin/bash

set -e

# this script does mirroring 

function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi


if [[ "$OCP_RELEASE" == "" ]]; then
  usage OCP_RELEASE
fi

if [[ "$OCP_LOCAL_REPOSITORY" == "" ]]; then
  usage OCP_LOCAL_REPOSITORY
fi

if [[ "$OCP_PRODUCT_REPO" == "" ]]; then
  usage OCP_PRODUCT_REPO
fi

if [[ "$OCP_RELEASE_NAME" == "" ]]; then
  usage OCP_RELEASE_NAME
fi

if [[ "$OCP_MIRROR_REGISTRY_HOST_NAME" == "" ]]; then
  usage OCP_MIRROR_REGISTRY_HOST_NAME
fi

if [[ "$OCP_MIRROR_REGISTRY_PORT" == "" ]]; then
  usage OCP_MIRROR_REGISTRY_PORT
fi

__local_registry=$OCP_MIRROR_REGISTRY_HOST_NAME.$OCP_DOMAIN:$OCP_MIRROR_REGISTRY_PORT
__local_secret_json=pull-secret-bundle.json

oc adm -a ${__local_secret_json} release mirror --from=quay.io/${OCP_PRODUCT_REPO}/${OCP_RELEASE_NAME}:${OCP_RELEASE} --to=${__local_registry}/${OCP_LOCAL_REPOSITORY} --to-release-image=${__local_registry}/${OCP_LOCAL_REPOSITORY}:${OCP_RELEASE} 2>&1 | tee mirror-output.txt
