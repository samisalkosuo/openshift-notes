function createZoneFile
{
    #OCP_NODE_BASTION is also DNS server
    __hostname_bastion=$(echo  $OCP_NODE_BASTION | awk '{print $1}')
    __ip_bastion=$(echo  $OCP_NODE_BASTION | awk '{print $2}')
    __hostname_haproxy=$(echo  $OCP_NODE_HAPROXY | awk '{print $1}')
    __ip_haproxy=$(echo  $OCP_NODE_HAPROXY | awk '{print $2}')
    __hostname_bootstrap=$(echo  $OCP_NODE_BOOTSTRAP | awk '{print $1}')
    __ip_bootstrap=$(echo  $OCP_NODE_BOOTSTRAP | awk '{print $2}')
    __hostname_master01=$(echo  $OCP_NODE_MASTER_01 | awk '{print $1}')
    __ip_master01=$(echo  $OCP_NODE_MASTER_01 | awk '{print $2}')
    __hostname_master02=$(echo  $OCP_NODE_MASTER_02 | awk '{print $1}')
    __ip_master02=$(echo  $OCP_NODE_MASTER_02 | awk '{print $2}')
    __hostname_master03=$(echo  $OCP_NODE_MASTER_03 | awk '{print $1}')
    __ip_master03=$(echo  $OCP_NODE_MASTER_03 | awk '{print $2}')

    __zone_file=${__omg_runtime_dir}/${OCP_DOMAIN}.zone

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
    echo "${__hostname_haproxy}   IN  A  ${__ip_haproxy}" >> $__zone_file
    echo "${__hostname_bootstrap} IN  A  ${__ip_bootstrap}" >> $__zone_file
    echo "${__hostname_master01}  IN  A  ${__ip_master01}" >> $__zone_file
    echo "${__hostname_master02}  IN  A  ${__ip_master02}" >> $__zone_file
    echo "${__hostname_master03}  IN  A  ${__ip_master03}" >> $__zone_file
    #add records from env variables
    #if three node cluster, ignore OCP_NODE_WORKER_HOSTS
    if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    echo $OCP_NODE_WORKER_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
    fi
    echo $OCP_OTHER_HOSTS_DHCP | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
    echo $OCP_OTHER_DNS_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file

    echo "\$ORIGIN ${OCP_CLUSTER_NAME}.${OCP_DOMAIN}." >> $__zone_file
    echo "api     IN  A      ${__ip_haproxy}" >> $__zone_file
    echo "api-int IN  CNAME  api" >> $__zone_file

    echo "\$ORIGIN apps.${OCP_CLUSTER_NAME}.${OCP_DOMAIN}." >> $__zone_file
    echo "*       IN  A      ${__ip_haproxy}" >> $__zone_file

}

function configureDNS
{
    echo "Configuring DNS..."

    #modify named.conf
    echo "Creating named.conf..."
    local __named_conf=$__omg_runtime_dir/named.conf
    cp templates/named.conf.template ${__named_conf}

    sed -i s!%DNSSERVERS%!${OCP_DNS_FORWARDERS}!g ${__named_conf}
    sed -i s!%ALLOWED_NETWORKS%!${OCP_DNS_ALLOWED_NETWORKS}!g ${__named_conf}
    sed -i s!%OCP_DOMAIN%!${OCP_DOMAIN}!g ${__named_conf}
    #commenting out option
    sed -i "s/directory/#directory/g" ${__named_conf}
    sed -i "s/pid-file/#pid-file/g" ${__named_conf}

    echo "Creating zone file..."
    createZoneFile
    echo "Copying DNS config files..."
    cp ${__named_conf} /etc/named.conf
    cp $__omg_runtime_dir/*zone /var/named
    #change ownership
    chown named:named /var/named/*.zone

    echo "Starting and enabling DNS (named) server..."
    systemctl daemon-reload
    systemctl enable named
    systemctl restart named

    #echo "Adding bastion host $OCP_NODE_BASTION_IP_ADDRESS to resolv.conf using Network Manager..."
    #nmcli con |grep -v NAME| awk -v IP=$OCP_NODE_BASTION_IP_ADDRESS '{print "nmcli con mod " $1 " ipv4.dns \"" IP "\""}' |sh
    #connection down then up...
    #nmcli con |grep -v NAME| awk '{print "nmcli con down " $1 " && nmcli con up " $1}' |sh

    echo "Adding local DNS server to /etc/resolv.conf and disabling Network Manager DNS configuration..."
    cat > /etc/NetworkManager/conf.d/90-dns-none.conf << EOF
[main]
dns=none
EOF
    systemctl reload NetworkManager
    #creating new /etc/resolv.conf
    cat > /etc/resolv.conf << EOF
#Created by $0 script
search $OCP_DOMAIN
nameserver $OCP_NODE_BASTION_IP_ADDRESS
EOF

    echo "Configuring DNS...done."
}
