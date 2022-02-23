#Env variables for UPI OpenShift install

#path to pull-secret.json
export OCP_PULL_SECRET_FILE=/root/pull-secret.json

#OCP version to install/upgrade
#check https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
#for desired version 
export OCP_VERSION=4.6.42

#Find correct RHCOS major release and version from
#https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/
#match RHCOS with chosen OCP
export OCP_RHCOS_MAJOR_RELEASE=4.6
export OCP_RHCOS_VERSION=4.6.40

#if installing with proxy
#uncomment and edit following variables
#export OCP_HTTP_PROXY=
#export OCP_HTTPS_PROXY=
#export OCP_NO_PROXY=

#modify after boostrap is complete and installation instructs to remove bootstrap and then:
#  set this to "yes"
#  shutdown bootstrap node 
#  if using gobetween loadbalancer, execute setup-load-balancer to remove bootstrap node 
export OCP_BOOTSTRAP_COMPLETE=no

#set this variable is cluster is only three nodes (that is, 3 masters)
#use values 'yes' or 'no'
export OCP_THREE_NODE_CLUSTER=no

#OCP_DOMAIN is your domain where OpenShift is installed
export OCP_DOMAIN=forum.fi.ibm.com
export OCP_CLUSTER_NAME=ocp07

#Bastion IP address, used in other variables, for example as NTP/DNS server
export OCP_NODE_BASTION_IP_ADDRESS=192.168.47.3

#host and port for Apache servers that hold RHCOS and ignition files
#typically bastion is the Apache host
export OCP_APACHE_HOST=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_APACHE_PORT=8080

#bastion and load balancer hostname and IP (used in DHCP and DNS, MAC is not required) 
export OCP_NODE_BASTION="bastion ${OCP_NODE_BASTION_IP_ADDRESS}"
export OCP_NODE_LB="lb ${OCP_NODE_BASTION_IP_ADDRESS}"

#bootstrap and master nodes that are served by DNS and DHCP server
#hostname, IP and MAC required
export OCP_NODE_BOOTSTRAP="bootstrap 192.168.47.31 00:50:56:b3:ad:48"
export OCP_NODE_MASTER_01="master1 192.168.47.32 00:50:56:b3:23:9a"
export OCP_NODE_MASTER_02="master2 192.168.47.33 00:50:56:b3:a2:0f"
export OCP_NODE_MASTER_03="master3 192.168.47.34 00:50:56:b3:0b:4f"

#OCP worker nodes that are served by DNS and DHCP server
#hostname, IP and MAC required
#syntax: "<HOSTNAME> <IP> <MAC>; <HOSTNAME> <IP> <MAC>;"
#where hostname, ip and mac are separated by space and followed by ;
#note: if OCP_THREE_NODE_CLUSTER is yes, then this variable is ignored
#note: if not using three node cluster, at least two workers are required
#the first two workers are used as router hosts and configured in load balancer
export OCP_NODE_WORKER_HOSTS=" \
worker01 192.168.47.40 00:50:56:b3:b8:3b  ; \
worker02 192.168.47.41 00:50:56:b3:a4:01  ; \
worker03 192.168.47.42 00:50:56:b3:cf:91  ; \
"

#other hosts in the OCP environment
# these are in DNS but not in DHCP
#syntax: "<HOSTNAME> <IP>; <HOSTNAME> <IP>;"
export OCP_OTHER_DNS_HOSTS=" \
mirror-registry 192.168.47.3; \
registry 192.168.47.3; \
ocp-registry 192.168.47.3; \
external-registry 192.168.47.3;\
"

#network CIDR for OCP nodes, used in install-config.yaml
export OCP_NODE_NETWORK_CIDR=192.168.47.0/24

#change to correct server address
#these are used by OpenShift cluster
export OCP_NTP_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_DNS_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}

#DNS config
#DNS_FORWARDERS format: space separated list of DNS servers"
export DNS_FORWARDERS="10.31.0.10 10.31.11.10 "

#DHCP config
#OpenShift nodes specified above are added to DHCP configuration

#dhcp server ip address, this is typically bastion but can be other server
#this IP address must be IP address where DHCP server is running
export OCP_DHCP_SERVER_IP_ADDRESS=${OCP_NODE_BASTION_IP_ADDRESS}

#Network information for DHCP server
#network interface that is used by DHCP, this interface is in the host where DHCP container is running
#make sure to set DHCP network interface to correct interface
export OCP_DHCP_NETWORK_INTERFACE=ens192
export OCP_DHCP_NETWORK=192.168.47.0
export OCP_DHCP_NETWORK_MASK=255.255.255.0
export OCP_DHCP_NETWORK_BROADCAST_ADDRESS=192.168.47.255
#if having more than one router, NTP or DNS server, separate them using comma ','
export OCP_DHCP_NETWORK_ROUTER=192.168.47.4
export OCP_DHCP_NTP_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_DHCP_DNS_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
#DHCP server range to dynamically give IP address
#mainly for OpenShift IPI installation
#export OCP_DHCP_IP_RANGE="192.168.47.190 192.168.47.240"

#client versions
. scripts/env/client_versions.sh

#GOVC environment variables
#uncomment and set GOVC_ environment variables if you want to use govc to control vcenter
#to create and delete VMs for OpenShift install
#if not using govc, VMs are easy to create manually
#see https://github.com/vmware/govmomi/tree/master/govc

# export GOVC_URL=
# export GOVC_USERNAME=
# export GOVC_PASSWORD=
# export GOVC_INSECURE=
# export GOVC_DATACENTER=
# export GOVC_DATASTORE=
# export GOVC_CLUSTER=
# export GOVC_NETWORK=
# export GOVC_RESOURCE_POOL=
# export GOVC_FOLDER=
# export GOVC_INSECURE=
#create VMs to specific host
#export GOVC_HOST=

