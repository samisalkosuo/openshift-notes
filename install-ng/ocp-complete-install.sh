#!/bin/sh

if [[ "$OMG_OCP_CLUSTER_NAME" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

set -e

#OpenShift install dir, used while installing OpenShift
#holds kubeconfig authentication file in auth-subdirectory
__dir_suffix=${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN}
__openshift_install_dir=~/ocp-install-${__dir_suffix}

function ocpCompleteInstall
{
  local __current_dir=$(pwd)
  cd $__openshift_install_dir/
  openshift-install --dir=./ wait-for install-complete 2>&1 | tee install-complete.txt
  cd $__current_dir
}

ocpCompleteInstall
