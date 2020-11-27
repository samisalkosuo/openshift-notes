
function usage
{
  echo "Usage: $0 <IGN_URL> <MAC_ADDRESS> <DIR>"
  exit 1
}

function usage2
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_PXE_RHCOS_KERNEL_URL" == "" ]]; then
  usage OCP_PXE_RHCOS_KERNEL_URL
fi

if [[ "$OCP_PXE_RHCOS_INITRAMFS_URL" == "" ]]; then
  usage OCP_PXE_RHCOS_INITRAMFS_URL
fi

if [[ "$OCP_PXE_RHCOS_ROOTFS_URL" == "" ]]; then
  usage OCP_PXE_RHCOS_ROOTFS_URL
fi



if [[ "$1" == "" ]]; then
  echo "Ignition URL (bootstrap,master or worker) is missing."
  usage
fi
if [[ "$2" == "" ]]; then
  echo "MAC address is missing."
  usage
fi

if [[ "$3" == "" ]]; then
  echo "directory is missing."
  usage
fi
__ignition_url=$1

__mac=$2
__macdashes=$(echo ${__mac} | sed "s/:/-/g")
#01-00-50-56-b3-65-44

_file=$3/"01-$__macdashes" 

echo "DEFAULT pxeboot" > ${_file}
echo "TIMEOUT 20" >> ${_file}
echo "PROMPT 0" >> ${_file}
echo "LABEL pxeboot" >> ${_file}
echo "    KERNEL ${OCP_PXE_RHCOS_KERNEL_URL}" >> ${_file}
echo "    APPEND initrd=${OCP_PXE_RHCOS_INITRAMFS_URL} coreos.live.rootfs_url=${OCP_PXE_RHCOS_ROOTFS_URL} coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=${__ignition_url}" >> ${_file}
    