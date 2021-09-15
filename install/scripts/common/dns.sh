
__zone_file=${__omg_runtime_dir}/${OCP_DOMAIN}.zone

function createZoneFile
{
    local __hostname_bastion=$(echo  $OCP_NODE_BASTION | awk '{print $1}')
    local __ip_bastion=$(echo  $OCP_NODE_BASTION | awk '{print $2}')
    local __hostname_loadbalancer=$(echo  $OCP_NODE_LB | awk '{print $1}')
    local __ip_loadbalancer=$(echo  $OCP_NODE_LB | awk '{print $2}')
    local __hostname_bootstrap=$(echo  $OCP_NODE_BOOTSTRAP | awk '{print $1}')
    local __ip_bootstrap=$(echo  $OCP_NODE_BOOTSTRAP | awk '{print $2}')
    local __hostname_master01=$(echo  $OCP_NODE_MASTER_01 | awk '{print $1}')
    local __ip_master01=$(echo  $OCP_NODE_MASTER_01 | awk '{print $2}')
    local __hostname_master02=$(echo  $OCP_NODE_MASTER_02 | awk '{print $1}')
    local __ip_master02=$(echo  $OCP_NODE_MASTER_02 | awk '{print $2}')
    local __hostname_master03=$(echo  $OCP_NODE_MASTER_03 | awk '{print $1}')
    local __ip_master03=$(echo  $OCP_NODE_MASTER_03 | awk '{print $2}')

    echo "\$ORIGIN ${OCP_DOMAIN}." >> $__zone_file
    echo "\$TTL    14400" > $__zone_file
    echo "@ IN SOA ns.${OCP_DOMAIN}. hostmaster.${OCP_DOMAIN}. (" >> $__zone_file
    echo "  2020022306 ; serial" >> $__zone_file
    echo "  3H ; refresh" >> $__zone_file
    echo "  15 ; retry" >> $__zone_file
    echo "  1w ; expire" >> $__zone_file
    echo "  3h ; nxdomain ttl" >> $__zone_file
    echo " )" >> $__zone_file
    echo "@ IN NS ns.${OCP_DOMAIN}." >> $__zone_file

    echo "\$ORIGIN ${OCP_DOMAIN}." >> $__zone_file
    echo "ns                      IN  A  ${__ip_bastion}" >> $__zone_file
    echo "hostmaster              IN  A  ${__ip_bastion}" >> $__zone_file
    echo "bastion                 IN  A  ${__ip_bastion}" >> $__zone_file
    #TODO: refactor
    if [[ "$__hostname_loadbalancer" != "" ]]; then
        echo "${__hostname_loadbalancer}   IN  A  ${__ip_loadbalancer}" >> $__zone_file
    fi
    if [[ "$__hostname_bootstrap" != "" ]]; then
        echo "${__hostname_bootstrap} IN  A  ${__ip_bootstrap}" >> $__zone_file
    fi
    if [[ "$__hostname_master01" != "" ]]; then
        echo "${__hostname_master01}  IN  A  ${__ip_master01}" >> $__zone_file
    fi
    if [[ "$__hostname_master02" != "" ]]; then
        echo "${__hostname_master02}  IN  A  ${__ip_master02}" >> $__zone_file
    fi
    if [[ "$__hostname_master03" != "" ]]; then
        echo "${__hostname_master03}  IN  A  ${__ip_master03}" >> $__zone_file
    fi
    # echo "${__hostname_loadbalancer}   IN  A  ${__ip_loadbalancer}" >> $__zone_file
    # echo "${__hostname_bootstrap} IN  A  ${__ip_bootstrap}" >> $__zone_file
    # echo "${__hostname_master01}  IN  A  ${__ip_master01}" >> $__zone_file
    # echo "${__hostname_master02}  IN  A  ${__ip_master02}" >> $__zone_file
    # echo "${__hostname_master03}  IN  A  ${__ip_master03}" >> $__zone_file
    #add records from env variables
    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    echo $OCP_NODE_WORKER_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
    fi
    #echo $OCP_OTHER_HOSTS_DHCP | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
    echo $OCP_OTHER_DNS_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file

    echo "\$ORIGIN ${OCP_CLUSTER_NAME}.${OCP_DOMAIN}." >> $__zone_file
    echo "api     IN  A      ${__ip_loadbalancer}" >> $__zone_file
    echo "api-int IN  CNAME  api" >> $__zone_file

    echo "\$ORIGIN apps.${OCP_CLUSTER_NAME}.${OCP_DOMAIN}." >> $__zone_file
    echo "*       IN  A      ${__ip_loadbalancer}" >> $__zone_file

}


function setupDNS
{
    echo "Configuring CoreDNS..."

    createZoneFile

    #coredns directory
    local __coredns_dir=/etc/coredns
    mkdir -p ${__coredns_dir}

    #coredns systemd config
    #https://github.com/coredns/deployment/tree/master/systemd

    cp $__zone_file ${__coredns_dir}/

    #add user
    useradd coredns -s /sbin/nologin -c 'coredns user' || true

    #service file
    cat > /etc/systemd/system/coredns.service << EOF
[Unit]
Description=CoreDNS DNS server
Documentation=https://coredns.io
After=network.target

[Service]
PermissionsStartOnly=true
LimitNOFILE=1048576
LimitNPROC=512
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
User=coredns
WorkingDirectory=/home/coredns
ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
ExecReload=/bin/kill -SIGUSR1 $MAINPID
Restart=on-failure
KillMode=control-group
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    #coredns config file
    cat > ${__coredns_dir}/Corefile << EOF
.:53 {
    forward . ${DNS_FORWARDERS}
    errors
}

${OCP_DOMAIN}:53 {
    file ${__coredns_dir}/${OCP_DOMAIN}.zone
    log
    errors
}
EOF

    echo "Starting and enabling coredns DNS server..."
    systemctl daemon-reload
    systemctl enable coredns
    systemctl restart coredns


    echo "Adding local DNS server to /etc/resolv.conf and disabling Network Manager DNS configuration..."
    cat > /etc/NetworkManager/conf.d/90-dns-none.conf << EOF
[main]
dns=none
EOF

    systemctl reload NetworkManager
    #creating new /etc/resolv.conf
    cat > /etc/resolv.conf << EOF
#Created by $0 script
#Overwritten when executing script again
search $OCP_DOMAIN
nameserver $OCP_DNS_SERVER
EOF

    echo "Configuring CoreDNS...done."
}
