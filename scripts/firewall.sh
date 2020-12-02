#omg.sh firewall related functions and commands

if [[ "${__operation}" == "firewall-close" ]]; then
  # NTP
  firewall-cmd --remove-port=123/udp
  #DNS
  firewall-cmd --remove-port=53/udp --remove-port=53/tcp
  #DHCP/TFTP
  firewall-cmd --remove-port=67/udp --remove-port=69/udp

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-open" ]]; then
  check_role "jump bastion bastion_online"
  
  #NTP
  firewall-cmd --add-port=123/udp
  #DNS
  firewall-cmd --add-port=53/udp --add-port=53/tcp
  #DHCP/TFTP
  firewall-cmd --add-port=67/udp --add-port=69/udp

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-open-haproxy" ]]; then
  check_role haproxy
  #HTTP/HTTPS
  firewall-cmd --add-port=80/tcp --add-port=443/tcp 
  #OpenShift API
  firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-close-haproxy" ]]; then
  check_role haproxy
  #HTTP/HTTPS
  firewall-cmd --remove-port=80/tcp --remove-port=443/tcp 
  #OpenShift API
  firewall-cmd --remove-port=6443/tcp --remove-port=22623/tcp 

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi
