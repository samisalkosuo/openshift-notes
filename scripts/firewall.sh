#omg.sh firewall related functions and commands

function open_port
{
   local port=$1
   local zone=$2
   echo "Open $port in zone $zone..."
   firewall-cmd --add-port=$port --zone=$zone
}

function close_port
{
   local port=$1
   local zone=$2
   echo "Closing $port in zone $zone..."
   firewall-cmd --remove-port=$port --zone=$zone
}


if [[ "${__operation}" == "firewall-close" ]]; then

  echo "Closing ports on all zones..."

  zones=$(firewall-cmd --get-zones)
  ports=('53/udp' '53/tcp' '67/udp' '69/udp' '123/udp')
  for zone in $zones
  do
    for port in "${ports[@]}"
    do
      close_port "$port" "$zone"
    done
  done

  # NTP
  #firewall-cmd --remove-port=123/udp
  #DNS
  #firewall-cmd --remove-port=53/udp --remove-port=53/tcp
  #DHCP/TFTP
  #firewall-cmd --remove-port=67/udp --remove-port=69/udp

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-open" ]]; then
  check_role "jump bastion bastion_online"
  
  echo "Opening ports on all zones..."

  zones=$(firewall-cmd --get-zones)
  ports=('53/udp' '53/tcp' '67/udp' '69/udp' '123/udp')
  for zone in $zones
  do
    for port in "${ports[@]}"
    do
      open_port "$port" "$zone"
    done
  done

  #NTP
  #firewall-cmd --add-port=123/udp
  #DNS
  #firewall-cmd --add-port=53/udp --add-port=53/tcp
  #DHCP/TFTP
  #firewall-cmd --add-port=67/udp --add-port=69/udp

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-open-haproxy" ]]; then
  #check_role haproxy
  
  zones=$(firewall-cmd --get-zones)
  ports=('80/tcp' '443/tcp' '6443/tcp' '22623/tcp')
  for port in "${ports[@]}"
  do
    for zone in $zones
    do
      open_port "$port" "$zone"
    done
  done

  #HTTP/HTTPS
  #firewall-cmd --add-port=80/tcp --add-port=443/tcp 
  #OpenShift API
  #firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi

if [[ "${__operation}" == "firewall-close-haproxy" ]]; then
  #check_role haproxy
  zones=$(firewall-cmd --get-zones)
  ports=('80/tcp' '443/tcp' '6443/tcp' '22623/tcp')
  for port in "${ports[@]}"
  do
    for zone in $zones
    do
      close_port "$port" "$zone"
    done
  done
  #HTTP/HTTPS
  #firewall-cmd --remove-port=80/tcp --remove-port=443/tcp 
  #OpenShift API
  #firewall-cmd --remove-port=6443/tcp --remove-port=22623/tcp 

  #persist firewall settings
  firewall-cmd --runtime-to-permanent
fi
