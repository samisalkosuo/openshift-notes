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

function ocpCompleteBootstrap
{
  echo "Waiting for bootstrap..."
  if [ ! -d "${__openshift_install_dir}" ]
  then
      echo "Directory ${__openshift_install_dir} does not exist." 
      error "Have you prepared to install OpenShift?" 
  fi
  local __current_dir=$(pwd)
  #local timestamp=$(date "+%Y%m%d%H%M%S")
  cd $__openshift_install_dir/
  openshift-install --dir=./ wait-for bootstrap-complete --log-level debug 2>&1 | tee ${__omg_runtime_dir}/bootstrap-complete.txt
  cd $__current_dir
  echo "Waiting for bootstrap...done."
}

ocpCompleteBootstrap
