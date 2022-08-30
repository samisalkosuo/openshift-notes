#!/bin/sh

#downloads coreos


if [[ "$OMG_OCP_VERSION" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi
set -e 

echo "Downloading RHCOS files..."

__dir=$(pwd)/rhcos
mkdir -p $__dir

#get download URLs from openshift install command
#see: https://docs.openshift.com/container-platform/4.10/installing/installing_bare_metal/installing-restricted-networks-bare-metal.html#installation-user-infra-machines-pxe_installing-restricted-networks-bare-metal
url_file=/tmp/rhcos_urls
openshift-install coreos print-stream-json | grep -Eo '"https.*(kernel-|initramfs.|rootfs.)\w+(\.img)?"' |grep x86_64 > $url_file

cat $url_file | awk -v dir=${__dir} '{print "curl -L " $1 "> " dir "/$(basename " $1 ")"}' |sh 

echo "Downloading RHCOS files...done."

#=== direct downloads below, above method is preferred

#Find correct RHCOS major release and version from
#https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/
#remember to match RHCOS version with OCP version
#export OMG_OCP_RHCOS_MAJOR_RELEASE=4.10
#export OMG_OCP_RHCOS_VERSION=4.10.16

function downloadFile
{
  #naming conventions
  #kernel: rhcos-<version>-live-kernel-<architecture>
  #initramfs: rhcos-<version>-live-initramfs.<architecture>.img
  #rootfs: rhcos-<version>-live-rootfs.<architecture>.img

  local dlurl=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${__release}/${__version}
  local dir=$2
  mkdir -p ${dir}
  if [ -f ${dir}/$1 ]; then
    echo "${dir}/$1 already downloaded."
  else
    #wget --directory-prefix=${dir} ${dlurl}/$1
    curl  ${dlurl}/$1 > ${dir}/$1
  fi 
}

function downloadRHCOSBinaries
{
    local __release=$OMG_OCP_RHCOS_MAJOR_RELEASE
    local __version=$OMG_OCP_RHCOS_VERSION
    local __architecture=x86_64
    local __dir=""
    if [[ "$1" == "" ]]; then
      #__dir=/var/www/html/rhcos
      #download RHCOS to rhcos directory
      __dir=$(pwd)/rhcos
      mkdir -p $__dir
    else
      __dir=$1
    fi

    echo "Downloading RHCOS ${__version} kernel to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-kernel-${__architecture} $__dir

    echo "Downloading RHCOS ${__version} initramfs to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-initramfs.${__architecture}.img $__dir

    echo "Downloading RHCOS ${__version} rootfs to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-rootfs.${__architecture}.img $__dir

    # echo "Downloading RHCOS ${__version} OVA to ${__dir}..."
    # downloadFile rhcos-${__version}-${__architecture}-vmware.${__architecture}.ova $__dir
    
}

#downloadRHCOSBinaries
