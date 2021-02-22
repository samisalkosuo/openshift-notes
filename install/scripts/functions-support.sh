#supporting functions for other functions

function error
{
    echo $1
    exit 1
}

function downloadFile
{
#naming conventions
#kernel: rhcos-<version>-live-kernel-<architecture>
#initramfs: rhcos-<version>-live-initramfs.<architecture>.img
#rootfs: rhcos-<version>-live-rootfs.<architecture>.img

   local dlurl=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${__release}/${__version}
   local dir=/var/www/html/rhcos
  if [ -f ${dir}/$1 ]; then
    echo "$1 already downloaded."
  else
    wget --directory-prefix=${dir} ${dlurl}/$1
  fi 
}


function downloadRHCOSBinaries
{
    local __release=$OCP_RHCOS_MAJOR_RELEASE
    local __version=$OCP_RHCOS_VERSION
    local __architecture=x86_64

    echo "Downloading RHCOS ${__version} kernel..."
    downloadFile rhcos-${__version}-${__architecture}-live-kernel-${__architecture}

    echo "Downloading RHCOS ${__version} initramfs..."
    downloadFile rhcos-${__version}-${__architecture}-live-initramfs.${__architecture}.img

    echo "Downloading RHCOS ${__version} rootfs..."
    downloadFile rhcos-${__version}-${__architecture}-live-rootfs.${__architecture}.img

}

#add hosts
function addHostToDHCPConf
{
  local __dhcpd_conf=dhcpd.conf
  echo  $1  | sed "s/;/\n/g" | awk -v file="${__dhcpd_conf}" '$1{print "sh scripts/add_host_entry_to_dhcp_conf.sh " $1 " " $2 " " $3 " " file}' |sh
}

function addPxeFile
{
  local ign_url=$2
  local __pxefiles_dir=dhcpd_pxe/pxelinux.cfg

  echo $1 | sed "s/;/\n/g" | awk -v ignurl="$ign_url" -v dir="${__pxefiles_dir}" '$1{print "sh scripts/add_pxe_file_for_host.sh " ignurl " "  $3 " " dir}' |sh 

}

function addEntry
{
  local __port=$2
  local __haproxy_cfg=haproxy.cfg
  echo $1 | awk -v port="${__port}" -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":" port " check\" >> " file}' | sh
}

function openPorts
{
  echo "Open NTP port..."
  firewall-cmd --add-port=123/udp
  echo "Open DNS ports..."
  firewall-cmd --add-port=53/udp --add-port=53/tcp
  echo "Open DHCP/TFTP ports..."
  firewall-cmd --add-port=67/udp --add-port=69/udp
  echo "Open HTTP/HTTPS ports..."
  firewall-cmd --add-port=80/tcp --add-port=443/tcp --add-port=8080/tcp 
  echo "Open OpenShift API ports..."
  firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 
  #persist firewall settings
  firewall-cmd --runtime-to-permanent

}

function closePorts
{
  echo "Close NTP port..."
  firewall-cmd --remove-port=123/udp
  echo "Close DNS ports..."
  firewall-cmd --remove-port=53/udp --remove-port=53/tcp
  echo "Close DHCP/TFTP ports..."
  firewall-cmd --remove-port=67/udp --remove-port=69/udp
  echo "Close HTTP/HTTPS ports..."
  firewall-cmd --remove-port=80/tcp --remove-port=443/tcp --remove-port=8080/tcp
  echo "Close OpenShift API ports..."
  firewall-cmd --remove-port=6443/tcp --remove-port=22623/tcp 
  #persist firewall settings
  firewall-cmd --runtime-to-permanent

}
