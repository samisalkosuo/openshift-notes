#!/bin/sh

#setup DHCP server, with PXE using dnsmasq and Apache server

if [[ "$OMG_OCP_APACHE_PORT" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

#dhcp configuration
__dhcpd_conf=/tmp/dhcpd.conf

#directory for PXE files
__pxe_dir=/tmp/dhcpd_pxe/pxelinux.cfg
mkdir -p ${__pxe_dir}

#URLs for RHCOS files and ignition files
#used in PXE variables, RHCOS files
__rhcos_kernel_url=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/rhcos/rhcos-${OMG_OCP_RHCOS_VERSION}-x86_64-live-kernel-x86_64
__rhcos_initramfs_url=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/rhcos/rhcos-${OMG_OCP_RHCOS_VERSION}-x86_64-live-initramfs.x86_64.img
__rhcos_rootfs_url=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/rhcos/rhcos-${OMG_OCP_RHCOS_VERSION}-x86_64-live-rootfs.x86_64.img

#Ignition files
__ignition_url_bootstrap=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/ignition/bootstrap.ign
__ignition_url_master=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/ignition/master.ign
__ignition_url_worker=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/ignition/worker.ign


function setupApache
{
    local htmlDir=/var/www/html
    mkdir -p $htmlDir/ignition

    # if [ -f "rhcos.tar" ]; then
    #   echo "extracting rhcos.tar..."
    #   tar -xf rhcos.tar
    #   echo "extracting rhcos.tar...done."
    # fi

    #move downloaded rhcos directory to Apache web server
    mv rhcos/ $htmlDir/
    
    __rhcos_kernel_url=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/rhcos/$(ls -1 $htmlDir/rhcos/ |grep kernel)
    __rhcos_initramfs_url=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/rhcos/$(ls -1 $htmlDir/rhcos/ |grep initramfs)
    __rhcos_rootfs_url=http://${OMG_OCP_APACHE_HOST}:${OMG_OCP_APACHE_PORT}/rhcos/$(ls -1 $htmlDir/rhcos/ |grep rootfs)


    #setting SELinux
    chcon -R -h -t httpd_sys_content_t $htmlDir
    echo "Configuring Apache..."
    set +e
    cat /etc/httpd/conf/httpd.conf |grep "Listen ${OMG_OCP_APACHE_PORT}" > /dev/null
    local rv=$?
    set -e
    if [ $rv -eq 1 ]; then
      echo "Changing Apache port to ${OMG_OCP_APACHE_PORT}..."
      sed -ibak "s/Listen 80/Listen ${OMG_OCP_APACHE_PORT}/g" /etc/httpd/conf/httpd.conf
    fi

    #creating index file
    cat > /var/www/html/index.html << EOF
<html>
<body>
<a href="./rhcos/">RHCOS binaries</a><br/>
<a href="./ignition/">Ignition files</a><br/>
</html>
</body>
EOF

    echo "Starting and enabling Apache server..."
    systemctl daemon-reload
    systemctl enable httpd
    systemctl restart httpd
#    echo "Open Apache ports..."
#    firewall-cmd --add-port=${OMG_OCP_APACHE_PORT}/tcp
    #persist firewall settings
#    firewall-cmd --runtime-to-permanent

    echo "Configuring Apache...done."
}

function setupDHCPServer
{
    #check if range is defined
    local dhcpRange=""
    if [[ -z "${OMG_OCP_DHCP_IP_RANGE}" ]]; then
      dhcpRange="#no IP address range"
    else
      dhcpRange="""
    #one day lease time
    default-lease-time 86400;
    #one week max lease time
    max-lease-time 604800;
    range ${OMG_OCP_DHCP_IP_RANGE};    
      """
    fi

    cat > ${__dhcpd_conf} << EOF
#DHCP configuration
subnet ${OMG_OCP_DHCP_NETWORK} netmask ${OMG_OCP_DHCP_NETWORK_MASK} {
    interface                  ${OMG_OCP_DHCP_NETWORK_INTERFACE};
    option subnet-mask         ${OMG_OCP_DHCP_NETWORK_MASK};
    option broadcast-address   ${OMG_OCP_DHCP_NETWORK_BROADCAST_ADDRESS};
    option routers             ${OMG_OCP_DHCP_NETWORK_ROUTER};
    option domain-name         "${OMG_OCP_DOMAIN}";
    option ntp-servers         ${OMG_OCP_DHCP_NTP_SERVER};
    option domain-name-servers ${OMG_OCP_DHCP_DNS_SERVER};
    option time-offset         7200;
    default-lease-time         7200;
    max-lease-time             86400;
    
    next-server                ${OMG_OCP_DHCP_SERVER_IP_ADDRESS};
    filename                   "lpxelinux.0";
    ${dhcpRange}

}
EOF

    addSingleHostToDHCPConfig "$OMG_OCP_NODE_BOOTSTRAP"
    addSingleHostToDHCPConfig "$OMG_OCP_NODE_MASTER_01"
    addSingleHostToDHCPConfig "$OMG_OCP_NODE_MASTER_02"
    addSingleHostToDHCPConfig "$OMG_OCP_NODE_MASTER_03"

    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OMG_OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
      addManyHostsToDHCPConfig "$OMG_OCP_NODE_WORKER_HOSTS"
    fi

    echo "Starting and enabling DHCP server..."
    cp ${__dhcpd_conf} /etc/dhcp/dhcpd.conf
    systemctl daemon-reload
    systemctl enable dhcpd
    systemctl restart dhcpd

#    echo "Open DHCP/TFTP ports..."
#    firewall-cmd --add-port=67/udp --add-port=69/udp
    #persist firewall settings
#    firewall-cmd --runtime-to-permanent

}


function setupTFTPServer
{
    echo "Configuring TFTP server..."

    #create tftp config
    #create PXE files that include PXE info
    #PXE file dir: dhcpd_pxe/pxelinux
    createPxeFile "$OMG_OCP_NODE_BOOTSTRAP" $__ignition_url_bootstrap
    createPxeFile "$OMG_OCP_NODE_MASTER_01" $__ignition_url_master
    createPxeFile "$OMG_OCP_NODE_MASTER_02" $__ignition_url_master
    createPxeFile "$OMG_OCP_NODE_MASTER_03" $__ignition_url_master

    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OMG_OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
      createManyPXEFiles "$OMG_OCP_NODE_WORKER_HOSTS" $__ignition_url_worker
    fi


    #disable dns in dnsmasq
    echo port=0 > /etc/dnsmasq.d/dns.conf
    #enable tftp
    echo "enable-tftp" > /etc/dnsmasq.d/tftpd.conf
    #echo "tftp-secure" >> /etc/dnsmasq.d/tftpd.conf
    echo "tftp-root=/usr/share/syslinux" >> /etc/dnsmasq.d/tftpd.conf
    #remove existing pxe files
    rm -rf /usr/share/syslinux/pxelinux.cfg
    #copy pxe files
    mv ${__pxe_dir} /usr/share/syslinux
    mkdir -p ${__pxe_dir}
    echo "Files moved to /usr/share/syslinux/pxelinux.cfg" > ${__pxe_dir}/README.txt
    echo "Configuring SELinux..."
    semanage fcontext -a -t public_content_t "/usr/share/syslinux/pxelinux.cfg" || true
    semanage fcontext -a -t public_content_t "/usr/share/syslinux/pxelinux.cfg(/.*)?" || true
    restorecon -R -v /usr/share/syslinux/pxelinux.cfg 
    cat > /tmp/my-dnsmasq.te << EOF
module my-dnsmasq 1.0;

require {
        type public_content_t;
        type admin_home_t;
        type dnsmasq_t;
        class file { getattr open read };
        class dir search;
}

#============= dnsmasq_t ==============

#!!!! This avc is allowed in the current policy
allow dnsmasq_t admin_home_t:file { getattr open read };

#!!!! This avc is allowed in the current policy
allow dnsmasq_t public_content_t:dir search;
allow dnsmasq_t public_content_t:file getattr;

#!!!! This avc is allowed in the current policy
allow dnsmasq_t public_content_t:file { open read };
EOF

    checkmodule -M -m -o /tmp/my-dnsmasq.mod /tmp/my-dnsmasq.te
    semodule_package -o /tmp/my-dnsmasq.pp -m /tmp/my-dnsmasq.mod
    semodule -i /tmp/my-dnsmasq.pp 

    echo "Starting and enabling TFTP server..."
    systemctl daemon-reload
    systemctl enable dnsmasq
    systemctl restart dnsmasq
    echo "Starting and enabling TFTP server...done."

}

function addSingleHostToDHCPConfig
{
  local hostInfo=($1)
  if [[ "${hostInfo[0]}" != "" ]]; then
    cat >> ${__dhcpd_conf} << EOF
host ${hostInfo[0]}  {
  hardware ethernet ${hostInfo[2]};
  fixed-address ${hostInfo[1]};
  option host-name "${hostInfo[0]}";
}
EOF
  fi
}

function addManyHostsToDHCPConfig
{
    local var=$1
    local SAVEIFS=$IFS   # Save current IFS
    IFS=$';'      # Change IFS to ;
    local arr=($var) # split to array 
    IFS=$SAVEIFS   # Restore IFS

    for hostInfo in "${arr[@]}"
    do
        addSingleHostToDHCPConfig "$hostInfo"
    done

}

function createPxeFile
{
  local hostInfo=($1)
  if [[ "${hostInfo[0]}" != "" ]]; then

    local __ignition_url=$2

    local __mac=${hostInfo[2]}
    local __macdashes=$(echo ${__mac} | sed "s/:/-/g")
    #mac becomes 01-00-50-56-b3-65-44
    local uppercaseFile=${__macdashes^^}
    local lowercaseFile=${__macdashes,,}
    cat > ${__pxe_dir}/01-$uppercaseFile << EOF
DEFAULT pxeboot
TIMEOUT 20
PROMPT 0
LABEL pxeboot
KERNEL ${__rhcos_kernel_url}
APPEND initrd=${__rhcos_initramfs_url} coreos.live.rootfs_url=${__rhcos_rootfs_url} coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=${__ignition_url}
EOF
    cat > ${__pxe_dir}/01-$lowercaseFile << EOF
DEFAULT pxeboot
TIMEOUT 20
PROMPT 0
LABEL pxeboot
KERNEL ${__rhcos_kernel_url}
APPEND initrd=${__rhcos_initramfs_url} coreos.live.rootfs_url=${__rhcos_rootfs_url} coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=${__ignition_url}
EOF

    fi
}

function createManyPXEFiles
{
    local var=$1
    local ignition_url=$2
    local SAVEIFS=$IFS   # Save current IFS
    IFS=$';'      # Change IFS to ;
    local arr=($var) # split to array 
    IFS=$SAVEIFS   # Restore IFS

    for hostInfo in "${arr[@]}"
    do
        createPxeFile "$hostInfo" ${ignition_url}
    done

}

#if vcenter variable is empty, assume UPI install
#and setup Apache
if [[ "$OMG_OCP_VSPHERE_VCENTER_FQDN" == "" ]]; then
  setupApache
fi
setupDHCPServer

#if vcenter variable is empty, assume UPI install
#and setup TFTP
if [[ "$OMG_OCP_VSPHERE_VCENTER_FQDN" == "" ]]; then
  setupTFTPServer
fi


