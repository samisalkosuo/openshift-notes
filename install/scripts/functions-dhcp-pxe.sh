
__dhcpd_conf=${__omg_runtime_dir}/dhcpd.conf

function addHostToDHCPConf
{
  echo  $1  | sed "s/;/\n/g" | awk -v file="${__dhcpd_conf}" '$1{print "sh scripts/add_host_entry_to_dhcp_conf.sh " $1 " " $2 " " $3 " " file}' |sh
}

function addPxeFile
{
  local ign_url=$2
  local __pxefiles_dir=${__omg_runtime_dir}/dhcpd_pxe/pxelinux.cfg

  echo $1 | sed "s/;/\n/g" | awk -v ignurl="$ign_url" -v dir="${__pxefiles_dir}" '$1{print "sh scripts/add_pxe_file_for_host.sh " ignurl " "  $3 " " dir}' |sh 

}

function configureDHCPandPXE
{
    echo "Configuring DHCP and PXE..."
    cp templates/dhcpd.conf.template ${__dhcpd_conf}
    sed -i s!%OCP_DOMAIN%!${OCP_DOMAIN}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_NETWORK%!${OCP_DHCP_NETWORK}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_NETWORK_MASK%!${OCP_DHCP_NETWORK_MASK}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_NETWORK_BROADCAST_ADDRESS%!${OCP_DHCP_NETWORK_BROADCAST_ADDRESS}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_NETWORK_ROUTER%!${OCP_DHCP_NETWORK_ROUTER}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_NTP_SERVER%!${OCP_DHCP_NTP_SERVER}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_DNS_SERVER%!${OCP_DHCP_DNS_SERVER}!g ${__dhcpd_conf}
    sed -i s!%OCP_DHCP_NETWORK_INTERFACE%!${OCP_DHCP_NETWORK_INTERFACE}!g ${__dhcpd_conf}
    sed -i s!%TFTP_SERVER%!${OCP_NODE_BASTION_IP_ADDRESS}!g ${__dhcpd_conf}

    addHostToDHCPConf "$OCP_NODE_BOOTSTRAP"
    addHostToDHCPConf "$OCP_NODE_MASTER_01"
    addHostToDHCPConf "$OCP_NODE_MASTER_02"
    addHostToDHCPConf "$OCP_NODE_MASTER_03"
    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
      addHostToDHCPConf "$OCP_NODE_WORKER_HOSTS"
    fi
    addHostToDHCPConf "$OCP_OTHER_HOSTS_DHCP"

    #create tftp config
    #create PXE files that include PXE info
    #PXE file dir: dhcpd_pxe/pxelinux
    mkdir -p ${__omg_runtime_dir}/dhcpd_pxe/pxelinux.cfg
    addPxeFile "$OCP_NODE_BOOTSTRAP" $OCP_IGNITION_URL_BOOTSTRAP
    addPxeFile "$OCP_NODE_MASTER_01" $OCP_IGNITION_URL_MASTER
    addPxeFile "$OCP_NODE_MASTER_02" $OCP_IGNITION_URL_MASTER
    addPxeFile "$OCP_NODE_MASTER_03" $OCP_IGNITION_URL_MASTER
    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
        addPxeFile "$OCP_NODE_WORKER_HOSTS" $OCP_IGNITION_URL_WORKER
    fi 
    addPxeFile "$OCP_OTHER_HOSTS_DHCP" $OCP_IGNITION_URL_WORKER

    cp ${__dhcpd_conf} /etc/dhcp/dhcpd.conf
    echo "Starting and enabling DHCP server..."
    systemctl daemon-reload
    systemctl enable dhcpd
    systemctl restart dhcpd

    echo "Configuring TFTP server"
    #disable dns in dnsmasq
    echo port=0 > /etc/dnsmasq.d/dns.conf
    #enable tftp
    echo "enable-tftp" > /etc/dnsmasq.d/tftpd.conf
    #echo "tftp-secure" >> /etc/dnsmasq.d/tftpd.conf
    echo "tftp-root=/usr/share/syslinux" >> /etc/dnsmasq.d/tftpd.conf
    #remove existing pxe files
    rm -rf /usr/share/syslinux/pxelinux.cfg
    #copy pxe files
    mv ${__omg_runtime_dir}/dhcpd_pxe/pxelinux.cfg /usr/share/syslinux
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
        
    echo "Configuring DHCP and PXE...done."

}
