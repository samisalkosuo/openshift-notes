#!/bin/bash

# this script downloads oc-client

function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_VERSION" == "" ]]; then
  usage OCP_VERSION
fi

set -e

if [ ! -f "/usr/local/bin/oc" ]; then
  __oc_client_filename=openshift-client-linux.tar.gz
  curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/${__oc_client_filename} > ${__oc_client_filename}

  echo "Copying oc and kubectl to /usr/local/bin/"
  tar  -C /usr/local/bin/ -xf ${__oc_client_filename}
fi

echo "oc version:"
oc version
