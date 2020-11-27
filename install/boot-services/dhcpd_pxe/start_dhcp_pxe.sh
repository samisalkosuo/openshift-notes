#! /bin/sh -e

#heavily inspired by https://github.com/instantlinux/docker-tools/tree/master/images/dhcpd-dns-pxe


#disable dns in dnsmasq
echo port=0 > /etc/dnsmasq.d/dns.conf
#start tftp in background
echo "tftp-root=/usr/share/syslinux" > /etc/dnsmasq.d/tftpd.conf
if [[ "$ENABLE_LOG" == "true" ]]; then
  #start dnsmasq in foreground and log to stdout/err
  dnsmasq --keep-in-foreground --log-facility=- --enable-tftp &
else
  dnsmasq --enable-tftp
fi



#change tftp server to container IP 
#the command retrieves IP address of specified interface that is not given by dhcp
__tftp_server=$(ip -o -4 addr show dev ${OCP_DHCP_NETWORK_INTERFACE} | grep -v dynamic | cut -d' ' -f7 | cut -d'/' -f1)
sed -i s!%TFTP_SERVER%!${__tftp_server}!g /etc/dhcp/dhcpd.conf

#start dhcp in foreground
touch /var/lib/dhcp/dhcpd.leases
chown dhcp /var/lib/dhcp/dhcpd.leases
__dhcpd_options="-f"
if [[ "$ENABLE_LOG" == "true" ]]; then
  #set -d option to log to stdout/err  
  __dhcpd_options="-d"
fi
exec dhcpd $__dhcpd_options -user dhcp -group daemon
