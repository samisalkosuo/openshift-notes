#setup DHCP server, with PXE using dnsmasq and Apache server

#dhcp configuration
__dhcpd_conf=${__omg_runtime_dir}/dhcpd.conf

#directory for PXE files
__pxe_dir=${__omg_runtime_dir}/dhcpd_pxe/pxelinux.cfg
mkdir -p ${__pxe_dir}

function setupDHCPandPXE
{
    echo "Configuring DHCP and PXE..."
    setupDHCPServer
    setupTFTPServer
    echo "Configuring DHCP and PXE...done."
}

function setupDHCPOnly
{
    echo "Configuring DHCP..."
    setupDHCPServer
    echo "Configuring DHCP...done."
}

#function setupDHCPandPXE2
function setupDHCPServer
{
    #echo "Configuring DHCP and PXE..."
    
    #check if range is defined
    local dhcpRange=""
    if [[ -z "${OCP_DHCP_IP_RANGE}" ]]; then
      dhcpRange="#no IP address range"
    else
      dhcpRange="""
    default-lease-time 86400000;
    max-lease-time 720000000;
    range ${OCP_DHCP_IP_RANGE};    
      """
    fi

    cat > ${__dhcpd_conf} << EOF
#DHCP configuration
subnet ${OCP_DHCP_NETWORK} netmask ${OCP_DHCP_NETWORK_MASK} {
    interface                  ${OCP_DHCP_NETWORK_INTERFACE};
    option subnet-mask         ${OCP_DHCP_NETWORK_MASK};
    option broadcast-address   ${OCP_DHCP_NETWORK_BROADCAST_ADDRESS};
    option routers             ${OCP_DHCP_NETWORK_ROUTER};
    option domain-name         "${OCP_DOMAIN}";
    option ntp-servers         ${OCP_DHCP_NTP_SERVER};
    option domain-name-servers ${OCP_DHCP_DNS_SERVER};
    option time-offset         7200;
    default-lease-time         720000000;
    max-lease-time             7200000000;
    
    next-server                ${OCP_DHCP_SERVER_IP_ADDRESS};
    filename                   "lpxelinux.0";
    ${dhcpRange}

}
EOF

    addSingleHostToDHCPConfig "$OCP_NODE_BOOTSTRAP"
    addSingleHostToDHCPConfig "$OCP_NODE_MASTER_01"
    addSingleHostToDHCPConfig "$OCP_NODE_MASTER_02"
    addSingleHostToDHCPConfig "$OCP_NODE_MASTER_03"

    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
      addManyHostsToDHCPConfig "$OCP_NODE_WORKER_HOSTS"
    fi

    echo "Starting and enabling DHCP server..."
    cp ${__dhcpd_conf} /etc/dhcp/dhcpd.conf
    systemctl daemon-reload
    systemctl enable dhcpd
    systemctl restart dhcpd

    # #create tftp config
    # #create PXE files that include PXE info
    # #PXE file dir: dhcpd_pxe/pxelinux
    # createPxeFile "$OCP_NODE_BOOTSTRAP" $__ignition_url_bootstrap
    # createPxeFile "$OCP_NODE_MASTER_01" $__ignition_url_master
    # createPxeFile "$OCP_NODE_MASTER_02" $__ignition_url_master
    # createPxeFile "$OCP_NODE_MASTER_03" $__ignition_url_master

    # #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    # if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    #   createManyPXEFiles "$OCP_NODE_WORKER_HOSTS" $__ignition_url_worker
    # fi

    #setupTFTPServer

}


function setupTFTPServer
{
    echo "Configuring TFTP server..."

    #create tftp config
    #create PXE files that include PXE info
    #PXE file dir: dhcpd_pxe/pxelinux
    createPxeFile "$OCP_NODE_BOOTSTRAP" $__ignition_url_bootstrap
    createPxeFile "$OCP_NODE_MASTER_01" $__ignition_url_master
    createPxeFile "$OCP_NODE_MASTER_02" $__ignition_url_master
    createPxeFile "$OCP_NODE_MASTER_03" $__ignition_url_master

    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
      createManyPXEFiles "$OCP_NODE_WORKER_HOSTS" $__ignition_url_worker
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
    set +e
    semodule -l |grep my-dnsmasq > /dev/null
    local rv=$?
    set -e
    if [ $rv -eq 0 ]; then
        echo "SELinux seems to be configured..."
    else
        semanage fcontext -a -t public_content_t "/usr/share/syslinux/pxelinux.cfg" || true
        semanage fcontext -a -t public_content_t "/usr/share/syslinux/pxelinux.cfg(/.*)?" || true
        restorecon -R -v /usr/share/syslinux/pxelinux.cfg 
        cat > ${__omg_runtime_dir}/my-dnsmasq.te << EOF
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

        checkmodule -M -m -o ${__omg_runtime_dir}/my-dnsmasq.mod ${__omg_runtime_dir}/my-dnsmasq.te
        semodule_package -o ${__omg_runtime_dir}/my-dnsmasq.pp -m ${__omg_runtime_dir}/my-dnsmasq.mod
        semodule -i ${__omg_runtime_dir}/my-dnsmasq.pp 
    fi

    echo "Starting and enabling TFTP server..."
    systemctl daemon-reload
    systemctl enable dnsmasq
    systemctl restart dnsmasq

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

    cat > ${__pxe_dir}/01-$__macdashes << EOF
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
