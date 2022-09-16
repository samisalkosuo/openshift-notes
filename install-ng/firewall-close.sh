#close firewall

if [[ "$OMG_OCP_APACHE_PORT" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi
set -e 

source firewall-open.sh

if [[ "$1" == "" ]]; then
  usage
  exit 1
fi

removeService $ZONE http
removeService $ZONE https
removeService $ZONE ntp
removeService $ZONE tftp
removeService $ZONE dhcp
removeService $ZONE dns
#removeService $ZONE ldap
#removeService $ZONE ldaps

removePort $ZONE 6443/tcp
removePort $ZONE 22623/tcp
removePort $ZONE $OMG_OCP_APACHE_PORT/tcp

firewall-cmd --runtime-to-permanent
firewall-cmd --reload

