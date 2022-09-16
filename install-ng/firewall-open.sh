#firewall scripts
#check https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7

if [[ "$OMG_OCP_APACHE_PORT" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi
set -e 

function usage
{
  echo "Zone not specifed."
  echo "Available zones:"
  firewall-cmd --get-zones
  echo "Active zones:"
  firewall-cmd --get-active-zones
  echo ""
  echo "For example, open firewall for public-zone:"
  echo "$0 public" 
}

if [[ "$1" == "" ]]; then
  usage
  exit 1
fi

#use services instead of ports, where possible
ZONE=$1

function addService
{
    local zone=$1
    local service=$2
    firewall-cmd --zone=$zone --add-service=$service 
}

function addPort
{
    local zone=$1
    local port=$2
    firewall-cmd --zone=$zone --add-port=$port 
}

function removeService
{
    local zone=$1
    local service=$2
    firewall-cmd --zone=$zone --remove-service=$service 
}

function removePort
{
    local zone=$1
    local port=$2
    firewall-cmd --zone=$zone --remove-port=$port 
}

addService $ZONE http
addService $ZONE https
addService $ZONE ntp
addService $ZONE tftp
addService $ZONE dhcp
addService $ZONE dns
#addService $ZONE ldap
#addService $ZONE ldaps

addPort $ZONE 6443/tcp
addPort $ZONE 22623/tcp
addPort $ZONE $OMG_OCP_APACHE_PORT/tcp

firewall-cmd --runtime-to-permanent
firewall-cmd --reload
