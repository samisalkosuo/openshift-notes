
function usage
{
  echo "Usage: $0 <HOSTNAME> <IP> <MAC_ADDRESS> <DHCPD_CONF_GILE>"
  exit 1
}

if [[ "$1" == "" ]]; then
  echo "Hostname is missing."
  usage
fi

if [[ "$2" == "" ]]; then
  echo "IP address is missing."
  usage
fi

if [[ "$3" == "" ]]; then
  echo "MAC address is missing."
  usage
fi

if [[ "$4" == "" ]]; then
  echo "dhcpd.conf file is missing."
  usage
fi

echo "host $1  {" >> $4
echo "  hardware ethernet $3;" >> $4
echo "  fixed-address $2;" >> $4
echo "  option host-name \"$1\";" >> $4
echo "}" >> $4
