
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
    wget --directory-prefix=${dir} ${dlurl}/$1
  fi 
}

function downloadRHCOSBinaries
{
    local __release=$OCP_RHCOS_MAJOR_RELEASE
    local __version=$OCP_RHCOS_VERSION
    local __architecture=x86_64
    local __dir=""
    if [[ "$1" == "" ]]; then
      __dir=/var/www/html/rhcos
    else
      __dir=$1
    fi

    echo "Downloading RHCOS ${__version} kernel to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-kernel-${__architecture} $__dir

    echo "Downloading RHCOS ${__version} initramfs to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-initramfs.${__architecture}.img $__dir

    echo "Downloading RHCOS ${__version} rootfs to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-live-rootfs.${__architecture}.img $__dir

    echo "Downloading RHCOS ${__version} OVA to ${__dir}..."
    downloadFile rhcos-${__version}-${__architecture}-vmware.${__architecture}.ova $__dir
    
}
