#!/bin/bash

set -e

# this script create install files to be used to install OpenShift in bastion server

function usageEnv
{
  echo "$1 env variable missing."
  exit 1
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usageEnv OCP_DOMAIN
fi

if [[ "$OCP_CLUSTER_NAME" == "" ]]; then
  usageEnv OCP_CLUSTER_NAME
fi

if [[ "$OCP_RELEASE" == "" ]]; then
  usageEnv OCP_RELEASE
fi

if [[ "$OCP_LOCAL_REPOSITORY" == "" ]]; then
  usageEnv OCP_LOCAL_REPOSITORY
fi

if [[ "$OCP_MIRROR_REGISTRY_PORT" == "" ]]; then
  usageEnv OCP_MIRROR_REGISTRY_PORT
fi

if [[ "$OCP_MIRROR_REGISTRY_HOST_NAME" == "" ]]; then
  usageEnv OCP_MIRROR_REGISTRY_HOST_NAME
fi

 if [[ "$OCP_NODE_NETWORK_CIDR" == "" ]]; then
   usageEnv OCP_NODE_NETWORK_CIDR
 fi



function usage
{
  echo "Usage: $0 <CA_CERTIFICATE_FILEPATH>"
  exit 1
}


if [[ "$1" == "" ]]; then
  echo "CA certificate path is missing."
  usage
fi

__local_registry=$OCP_MIRROR_REGISTRY_HOST_NAME.$OCP_DOMAIN:$OCP_MIRROR_REGISTRY_PORT
__network_cidr=$OCP_NODE_NETWORK_CIDR
__local_secret_json=pull-secret-bundle.json
__mirror_registry_secret_json=pull-secret-$OCP_MIRROR_REGISTRY_HOST_NAME.json
__ca_cert_file=$1

if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then

  echo "Downloading openshft-install from mirror registry..."
  oc adm -a ${__local_secret_json} release extract --command=openshift-install "${__local_registry}/${OCP_LOCAL_REPOSITORY}:${OCP_RELEASE}"
fi

echo "Creating install-config.yaml..."
__pull_secret_json=$(cat $__mirror_registry_secret_json | jq -c '')
if [[ "$OCP_OMG_SERVER_ROLE" == "bastion_online" ]]; then
  if [ ! -f "../../pull-secret.json" ]; then
    echo "pull-secret.json does not exit."
    exit 2
  fi
  __pull_secret_json=$(cat ../../pull-secret.json | jq -c '')
fi
#create install-config.yaml
__install_cfg_file=install-config.yaml
cp install-config.yaml.template $__install_cfg_file

#set variables
sed -i s/%OCP_DOMAIN%/${OCP_DOMAIN}/g $__install_cfg_file
sed -i s!%OCP_NODE_NETWORK_CIDR%!${__network_cidr}!g $__install_cfg_file
sed -i s/%OCP_CLUSTER_NAME%/${OCP_CLUSTER_NAME}/g $__install_cfg_file
sed -i s/%MIRROR_REGISTRY_PULL_SECRET%/${__pull_secret_json}/g $__install_cfg_file
#note that SSH key will be added later in bastion

#add CA certificate
echo "additionalTrustBundle: |" >> $__install_cfg_file
cat ${__ca_cert_file} | sed 's/^/\ \ \ \ \ /g' >> $__install_cfg_file

if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
  cat mirror-output.txt | grep -A7 imageContentSources >> $__install_cfg_file
fi
#remove empty lines if there are any
sed -i '/^[[:space:]]*$/d' $__install_cfg_file

echo "openshift-install downloaded and $__install_cfg_file created"
