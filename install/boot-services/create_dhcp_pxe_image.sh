#!/bin/bash


function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi


if [[ "$OCP_DHCP_NETWORK" == "" ]]; then
  usage OCP_DHCP_NETWORK
fi

if [[ "$OCP_DHCP_NETWORK_MASK" == "" ]]; then
  usage OCP_DHCP_NETWORK_MASK
fi

if [[ "$OCP_DHCP_NETWORK_BROADCAST_ADDRESS" == "" ]]; then
  usage OCP_DHCP_NETWORK_BROADCAST_ADDRESS
fi

if [[ "$OCP_DHCP_NETWORK_ROUTER" == "" ]]; then
  usage OCP_DHCP_NETWORK_ROUTER
fi

if [[ "$OCP_DHCP_NETWORK_INTERFACE" == "" ]]; then
  usage OCP_DHCP_NETWORK_INTERFACE
fi

if [[ "$OCP_DHCP_NTP_SERVER" == "" ]]; then
  usage OCP_DHCP_NTP_SERVER
fi

if [[ "$OCP_DHCP_DNS_SERVER" == "" ]]; then
  usage OCP_DHCP_DNS_SERVER
fi

#if three node cluster, ignore OCP_NODE_WORKER_HOSTS
if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
  if [[ "$OCP_NODE_WORKER_HOSTS" == "" ]]; then
    usage OCP_NODE_WORKER_HOSTS
  fi
fi

if [[ "$OCP_OTHER_HOSTS_DHCP" == "" ]]; then
  usage OCP_OTHER_HOSTS_DHCP
fi

if [[ "$OCP_SERVICE_NAME_DHCPPXE_SERVER" == "" ]]; then
  usage OCP_SERVICE_NAME_DHCPPXE_SERVER
fi

if [[ "$OCP_IGNITION_URL_BOOTSTRAP" == "" ]]; then
  usage OCP_IGNITION_URL_BOOTSTRAP
fi

if [[ "$OCP_IGNITION_URL_MASTER" == "" ]]; then
  usage OCP_IGNITION_URL_MASTER
fi

if [[ "$OCP_IGNITION_URL_WORKER" == "" ]]; then
  usage OCP_IGNITION_URL_WORKER
fi


__name=$OCP_SERVICE_NAME_DHCPPXE_SERVER

set -e


__dhcpd_conf=dhcpd_pxe/dhcpd.conf
echo "Creating dhcpd.conf..."

#modify dhcpd.conf
cp dhcpd_pxe/dhcpd.conf.template ${__dhcpd_conf}

sed -i s!%OCP_DOMAIN%!${OCP_DOMAIN}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_NETWORK%!${OCP_DHCP_NETWORK}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_NETWORK_MASK%!${OCP_DHCP_NETWORK_MASK}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_NETWORK_BROADCAST_ADDRESS%!${OCP_DHCP_NETWORK_BROADCAST_ADDRESS}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_NETWORK_ROUTER%!${OCP_DHCP_NETWORK_ROUTER}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_NTP_SERVER%!${OCP_DHCP_NTP_SERVER}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_DNS_SERVER%!${OCP_DHCP_DNS_SERVER}!g ${__dhcpd_conf}
sed -i s!%OCP_DHCP_NETWORK_INTERFACE%!${OCP_DHCP_NETWORK_INTERFACE}!g ${__dhcpd_conf}

#add hosts
function addHost
{
  echo  $1  | sed "s/;/\n/g" | awk -v file="${__dhcpd_conf}" '$1{print "sh dhcpd_pxe/add_host_entry_to_dhcp_conf.sh " $1 " " $2 " " $3 " " file}' |sh
}

addHost "$OCP_NODE_BOOTSTRAP"
addHost "$OCP_NODE_MASTER_01"
addHost "$OCP_NODE_MASTER_02"
addHost "$OCP_NODE_MASTER_03"
#if three node cluster, ignore OCP_NODE_WORKER_HOSTS
if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
  addHost "$OCP_NODE_WORKER_HOSTS"
fi
addHost "$OCP_OTHER_HOSTS_DHCP"

#create tftp config
#create PXE files that include PXE info
__pxefiles_dir=dhcpd_pxe/pxelinux
mkdir -p ${__pxefiles_dir}
function addPxeFile
{
  local ign_url=$2
  echo $1 | sed "s/;/\n/g" | awk -v ignurl="$ign_url" -v dir="${__pxefiles_dir}" '$1{print "sh dhcpd_pxe/add_pxe_file_for_host.sh " ignurl " "  $3 " " dir}' |sh 

}
addPxeFile "$OCP_NODE_BOOTSTRAP" $OCP_IGNITION_URL_BOOTSTRAP
addPxeFile "$OCP_NODE_MASTER_01" $OCP_IGNITION_URL_MASTER
addPxeFile "$OCP_NODE_MASTER_02" $OCP_IGNITION_URL_MASTER
addPxeFile "$OCP_NODE_MASTER_03" $OCP_IGNITION_URL_MASTER
#if three node cluster, ignore OCP_NODE_WORKER_HOSTS
if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
  addPxeFile "$OCP_NODE_WORKER_HOSTS" $OCP_IGNITION_URL_WORKER
fi 
addPxeFile "$OCP_OTHER_HOSTS_DHCP" $OCP_IGNITION_URL_WORKER

echo "Building ${__name} image..."

podman build  -t ${__name} --build-arg OCP_DHCP_NETWORK_INTERFACE=${OCP_DHCP_NETWORK_INTERFACE} ./dhcpd_pxe

echo "Creating service file for ${__name}:${__version} image..."
__service_file=dhcpd_pxe/${__name}.service
cp dhcpd_pxe/dhcppxe.service.template ${__service_file}

sed -i s!%SERVICE_NAME%!${__name}!g ${__service_file}

cp ${__service_file} /etc/systemd/system/
systemctl daemon-reload

echo "Service file created and copied to /etc/systemd/system/"

echo "Use following commands to interact with the registry:"
echo "  " systemctl start ${__name}
echo "  " systemctl stop ${__name}
echo "  " systemctl restart ${__name}
echo "  " systemctl status ${__name}
echo "  " systemctl enable ${__name}
