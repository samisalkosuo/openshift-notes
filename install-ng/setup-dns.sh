#!/bin/sh

#setup DNS server
#uses CoreDNS


if [[ "$OMG_OCP_DOMAIN" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

__zone_file=/tmp/${OMG_OCP_DOMAIN}.zone

function createZoneFile
{
    local __hostname_bootstrap=$(echo  $OMG_OCP_NODE_BOOTSTRAP | awk '{print $1}')
    local __ip_bootstrap=$(echo  $OMG_OCP_NODE_BOOTSTRAP | awk '{print $2}')
    local __hostname_master01=$(echo  $OMG_OCP_NODE_MASTER_01 | awk '{print $1}')
    local __ip_master01=$(echo  $OMG_OCP_NODE_MASTER_01 | awk '{print $2}')
    local __hostname_master02=$(echo  $OMG_OCP_NODE_MASTER_02 | awk '{print $1}')
    local __ip_master02=$(echo  $OMG_OCP_NODE_MASTER_02 | awk '{print $2}')
    local __hostname_master03=$(echo  $OMG_OCP_NODE_MASTER_03 | awk '{print $1}')
    local __ip_master03=$(echo  $OMG_OCP_NODE_MASTER_03 | awk '{print $2}')

    echo "\$ORIGIN ${OMG_OCP_DOMAIN}." >> $__zone_file
    echo "\$TTL    14400" > $__zone_file
    echo "@ IN SOA ns.${OMG_OCP_DOMAIN}. hostmaster.${OMG_OCP_DOMAIN}. (" >> $__zone_file
    echo "  2020022306 ; serial" >> $__zone_file
    echo "  3H ; refresh" >> $__zone_file
    echo "  15 ; retry" >> $__zone_file
    echo "  1w ; expire" >> $__zone_file
    echo "  3h ; nxdomain ttl" >> $__zone_file
    echo " )" >> $__zone_file
    echo "@ IN NS ns.${OMG_OCP_DOMAIN}." >> $__zone_file
    echo "" >> $__zone_file
    echo "\$ORIGIN ${OMG_OCP_DOMAIN}." >> $__zone_file
    echo "ns             IN  A  ${OMG_DNS_SERVER_IP}" >> $__zone_file
    echo "hostmaster     IN  A  ${OMG_DNS_SERVER_IP}" >> $__zone_file
    echo "bastion        IN  A  ${OMG_DNS_SERVER_IP}" >> $__zone_file
    #TODO: refactor
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
    
    #add records from env variables
    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OMG_OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
      echo $OMG_OCP_NODE_WORKER_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
    fi
  
    echo $OMG_OCP_OTHER_DNS_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
    echo "" >> $__zone_file
    echo "\$ORIGIN ${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN}." >> $__zone_file
    echo "api     IN  A      ${OMG_OCP_LOADBALANCER_IP}" >> $__zone_file
    echo "api-int IN  CNAME  api" >> $__zone_file
    echo "" >> $__zone_file
    echo "\$ORIGIN apps.${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN}." >> $__zone_file
    echo "*       IN  A      ${OMG_OCP_LOADBALANCER_IP}" >> $__zone_file

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
    forward . ${OMG_DNS_FORWARDERS}
    errors
}

${OMG_OCP_DOMAIN}:53 {
    file ${__coredns_dir}/${OMG_OCP_DOMAIN}.zone
    log
    errors
}
EOF

    echo "Starting and enabling coredns DNS server..."
    systemctl daemon-reload
    systemctl enable coredns
    systemctl restart coredns

    #setup DNS using NetworkManager nmcli CLI tool
    #https://serverfault.com/a/1064938
    nmcli -g name,type connection  show  --active | awk -F: '/ethernet|wireless/ { print $1 }' | while read connection
    do
        nmcli con mod "$connection" ipv6.ignore-auto-dns yes
        nmcli con mod "$connection" ipv4.ignore-auto-dns yes
        nmcli con mod "$connection" ipv4.dns "${OMG_DNS_SERVER_IP}"
        nmcli con down "$connection" && nmcli con up "$connection"
    done

#    echo "Open DNS ports..."
#    firewall-cmd --add-port=53/udp --add-port=53/tcp
    #persist firewall settings
#    firewall-cmd --runtime-to-permanent

    echo "Check CoreDNS status:"
    echo "  systemctl status coredns"
    echo ""
    echo "Configuring CoreDNS...done."
}

setupDNS

