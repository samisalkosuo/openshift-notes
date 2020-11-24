#!/bin/sh

#this script download RHCOS images

set -e


function usage
{
  echo "Usage: $0 <OPENSHIFT_RELEASE> <OPENSHIFT_VERSION>"
  echo "For example: $0 4.6 4.6.1"
  echo ""
  echo "Find correct RHCOS release and version from"
  echo "https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/"
  exit 1
}

if [[ "$1" == "" ]]; then
  echo "OpenShift release is missing."
  usage
fi

if [[ "$2" == "" ]]; then
  echo "OpenShift version is missing."
  usage
fi

__release=$1
__version=$2
__architecture=x86_64
__dir=/var/www/apache

#naming conventions
#kernel: rhcos-<version>-live-kernel-<architecture>
#initramfs: rhcos-<version>-live-initramfs.<architecture>.img
#rootfs: rhcos-<version>-live-rootfs.<architecture>.img

__dlurl=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${__release}/${__version}

#version info file
echo ${__version} > ${__dir}/version.txt
#create text file with file names
__txt_file=${__dir}/files.txt
touch ${__txt_file}
function download
{
  echo $1 >> ${__txt_file}
  wget --directory-prefix=${__dir} ${__dlurl}/$1
  #curl ${__dlurl}/$1 > ${__dir}/$1
}

echo "Downloading RHCOS ${__version} kernel..."
download rhcos-${__version}-${__architecture}-live-kernel-${__architecture}
echo "Downloading RHCOS ${__version} initramfs..."
download rhcos-${__version}-${__architecture}-live-initramfs.${__architecture}.img
echo "Downloading RHCOS ${__version} rootfs..."
download rhcos-${__version}-${__architecture}-live-rootfs.${__architecture}.img



