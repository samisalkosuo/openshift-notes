#!/bin/bash

#this script updates OpenShift global pull secret
#see also https://docs.openshift.com/container-platform/4.6/openshift_images/managing_images/using-image-pull-secrets.html#images-pulling-from-private-registries_using-image-pull-secrets


function usage
{
  echo "Usage: $0 <REGISTRY_URL> <REGISTRY_USER> <REGISTRY_PASSWORD>"
  echo ""
  echo "For example: $0 https://external-registry.forum.fi.ibm.com:5001 admin passw0rd"
  exit 1
}

if [[ "$1" == "" ]]; then
  echo "Registry URL is missing."
  usage
fi

if [[ "$2" == "" ]]; then
  echo "Registry user is missing."
  usage
fi

if [[ "$3" == "" ]]; then
  echo "Registry password is missing."
  usage
fi

echo "Updating global pull secret..."

__registry_url=$1
__registry_user=$2
__registry_password=$3

echo "Checking global pull secret..."
__dockercfg=$(oc -n openshift-config get secret pull-secret -o jsonpath={.data})
rc=$?
if [[ $rc == 0 ]]; then
  #pull secret seems to exist
  #extract pull secret json
  echo "Global pull secret exists. Using existing secret..."
  __pull_secret_json=$(echo $__dockercfg  |jq -r '.".dockerconfigjson"' | base64 -d)
else 
  echo "Global pull secret does not exist. Using new secret..."
  __pull_secret_json={}
fi

#add new authentication to pull secret
echo "Adding registry authentication to pull secret..."
__registry_secret=$(echo -n "${__registry_user_name}:${__registry_user_password}" | base64 -w0)
__email=mr.smith@openshift.installation
__new_pull_secret_file=new_pull_secret.json
#__new_pull_secret_json=$(echo $__pull_secret_json | jq -c  ".auths += {\"$__registry_url\": {\"auth\": \"$__registry_secret\",\"email\": \"$__email\"}}")
echo $__pull_secret_json | jq -c  ".auths += {\"$__registry_url\": {\"auth\": \"$__registry_secret\",\"email\": \"$__email\"}}" > ${__new_pull_secret_file}

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${__new_pull_secret_file}
rm -f ${__new_pull_secret_file}

echo "Updating global pull secret...done."
