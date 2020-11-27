#!/bin/bash

#this script create pull secret for local registry
#pull-secret.json from Red Hat must exist in this directory

function usage
{
  echo "$1 env variable missing."
  exit 1
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi

if [[ "$OCP_MIRROR_REGISTRY_HOST_NAME" == "" ]]; then
  usage OCP_MIRROR_REGISTRY_HOST_NAME
fi

if [[ "$OCP_MIRROR_REGISTRY_USER_NAME" == "" ]]; then
  usage OCP_MIRROR_REGISTRY_USER_NAME
fi

if [[ "$OCP_MIRROR_REGISTRY_USER_PASSWORD" == "" ]]; then
  usage OCP_MIRROR_REGISTRY_USER_PASSWORD
fi

if [[ "$OCP_MIRROR_REGISTRY_PORT" == "" ]]; then
  usage OCP_MIRROR_REGISTRY_PORT
fi

set -e 

__registry_name=$OCP_MIRROR_REGISTRY_HOST_NAME
__registry_user_name=$OCP_MIRROR_REGISTRY_USER_NAME
__registry_user_password=$OCP_MIRROR_REGISTRY_USER_PASSWORD
__registry_port=$OCP_MIRROR_REGISTRY_PORT

__registry_host=$__registry_name.$OCP_DOMAIN:$__registry_port
__mirror_registry_secret=$(echo -n "${__registry_user_name}:${__registry_user_password}" | base64 -w0)
__email=mr.smith@$OCP_DOMAIN

__pull_secret_bundle_file=pull-secret-bundle.json
__pull_secret_mirror_file=pull-secret-${__registry_name}.json
echo "Creating pull-secret-bundle.json with mirror registry authentication..."
cat pull-secret.json | jq  ".auths += {\"$__registry_host\": {\"auth\": \"REG_SECRET\",\"email\": \"$__email\"}}" | sed "s/REG_SECRET/$__mirror_registry_secret/" > $__pull_secret_bundle_file
echo "Creating pull-secret-${__registry_name}.json just for mirror registry authentication..."
echo '{"auths":{}}' | jq  ".auths += {\"$__registry_host\": {\"auth\": \"REG_SECRET\",\"email\": \"$__email\"}}" | sed "s/REG_SECRET/$__mirror_registry_secret/" > $__pull_secret_mirror_file

echo "Pull secret bundle with Red Hat and mirror registry secrets:"
echo "  $__pull_secret_bundle_file"
echo "Mirror registry pull secret:"
echo "  $__pull_secret_mirror_file"
