#Env variables for IPI OpenShift install

#path to pull-secret.json
export OCP_PULL_SECRET_FILE=/root/pull-secret.json

#VSphere variables
export OCP_VSPHERE_VCENTER_FQDN=
export OCP_VSPHERE_USER=
export OCP_VSPHERE_PASSWORD=
export OCP_VSPHERE_VIRTUAL_IP_API=
export OCP_VSPHERE_VIRTUAL_IP_INGRESS=
export OCP_VSPHERE_CLUSTER=
export OCP_VSPHERE_DATACENTER=
export OCP_VSPHERE_DATASTORE=
export OCP_VSPHERE_NETWORK=

export OCP_IPI_MASTER_CPU=8
export OCP_IPI_MASTER_RAM=16384
export OCP_IPI_MASTER_DISK_GB=120

export OCP_IPI_WORKER_COUNT=2
export OCP_IPI_WORKER_CPU=8
export OCP_IPI_WORKER_RAM=32768
export OCP_IPI_WORKER_DISK_GB=120

#OCP version to install/upgrade
#check https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
#for desired version 
export OCP_VERSION=4.6.42

#OCP_DOMAIN is your domain where OpenShift is installed
export OCP_DOMAIN=forum.fi.ibm.com
export OCP_CLUSTER_NAME=ocp07

#Bastion IP address, used in other variables, for example as NTP/DNS server
export OCP_NODE_BASTION_IP_ADDRESS=192.168.47.99

#bastion and load balancer hostname and IP (used in DHCP and DNS, MAC is not required) 
export OCP_NODE_BASTION="bastion ${OCP_NODE_BASTION_IP_ADDRESS}"
export OCP_NODE_LB="lb ${OCP_NODE_BASTION_IP_ADDRESS}"

#other hosts in the OCP environment
# these are in DNS but not in DHCP
#syntax: "<HOSTNAME> <IP>; <HOSTNAME> <IP>;"
export OCP_OTHER_DNS_HOSTS=" \
vc6 10.31.3.6; \
lab43 10.31.3.43; \
lab44 10.31.3.44; \
lab45 10.31.3.45;\
"
#network CIDR for OCP nodes, used in install-config.yaml
export OCP_NODE_NETWORK_CIDR=192.168.47.0/24

#change to correct server address
#these are used by DHCP and OpenShift cluster
export OCP_NTP_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_DNS_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}

#DNS config
#DNS_FORWARDERS format: space separated list of DNS servers"
export DNS_FORWARDERS="10.31.0.10 10.31.11.10 "

#DHCP config

#dhcp server ip address, this is typically bastion but can be other server
#this IP address must be IP address where DHCP server is running
export OCP_DHCP_SERVER_IP_ADDRESS=${OCP_NODE_BASTION_IP_ADDRESS}

#Network information for DHCP server
#network interface that is used by DHCP, this interface is in the host where DHCP container is running
#make sure to set DHCP network interface to correct interface
export OCP_DHCP_NETWORK_INTERFACE=ens224
export OCP_DHCP_NETWORK=192.168.47.0
export OCP_DHCP_NETWORK_MASK=255.255.255.0
export OCP_DHCP_NETWORK_BROADCAST_ADDRESS=192.168.47.255
#if having more than one router, NTP or DNS server, separate them using comma ','
export OCP_DHCP_NETWORK_ROUTER=192.168.47.2
export OCP_DHCP_NTP_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_DHCP_DNS_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
#DHCP server range to dynamically give IP address
#for OpenShift IPI installation
export OCP_DHCP_IP_RANGE="192.168.47.190 192.168.47.240"

#client versions
. scripts/env/client_versions.sh