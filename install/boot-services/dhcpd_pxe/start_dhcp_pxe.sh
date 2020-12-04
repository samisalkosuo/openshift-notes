#! /bin/sh -e

#heavily inspired by https://github.com/instantlinux/docker-tools/tree/master/images/dhcpd-dns-pxe


#disable dns in dnsmasq
echo port=0 > /etc/dnsmasq.d/dns.conf

echo "tftp-root=/usr/share/syslinux" > /etc/dnsmasq.d/tftpd.conf
__dnsmasq_options="--keep-in-foreground --enable-tftp"
if [[ "$ENABLE_LOG" == "true" ]]; then
  __dnsmasq_options="${__dnsmasq_options} --log-facility=-"
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

#start dhcpd in background
dhcpd $__dhcpd_options -user dhcp -group daemon &

#start tftp/dnsmasq in foreground
exec dnsmasq $__dnsmasq_options
