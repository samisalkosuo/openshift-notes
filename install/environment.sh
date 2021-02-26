#Env variables for native online OpenShift install

#path to pull-secret.json
export OCP_PULL_SECRET_FILE=/root/pull-secret.json

#when instructed during installation
#set this to no when removing bootstrap from haproxy 
export OCP_NODE_HAPROXY_ADD_BOOTSTRAP=yes

#OCP version to install/upgrade
#check https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
#for desired version 
export OCP_VERSION=4.6.8

#Find correct RHCOS major release and version from
#https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/
#match RHCOS with chosen OCP
export OCP_RHCOS_MAJOR_RELEASE=4.6
export OCP_RHCOS_VERSION=4.6.8

#set this variable is cluster is only three nodes (that is, 3 masters)
#use values 'yes' or 'no'
export OCP_THREE_NODE_CLUSTER=yes

#OCP_DOMAIN is your domain where OpenShift is installed
export OCP_DOMAIN=forum.fi.ibm.com
export OCP_CLUSTER_NAME=cluster2

#OpenShift install user, created in bastion server
export OCP_INSTALL_USER=ocp

export OCP_RELEASE="${OCP_VERSION}-x86_64"
export OCP_LOCAL_REPOSITORY='ocp/openshift4'
export OCP_PRODUCT_REPO='openshift-release-dev'
export OCP_RELEASE_NAME="ocp-release"

#Bastion IP address, used in other variables
export OCP_NODE_BASTION_IP_ADDRESS=192.168.47.20
#host and port for Apache servers that hold RHCOS and ignition files
#typically bastion is the Apache host
export OCP_APACHE_HOST=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_APACHE_PORT=8080

#network CIDR for OCP nodes, used in install-config.yaml
export OCP_NODE_NETWORK_CIDR=192.168.47.0/24

#bastion and haproxy hostname and IP (MAC is not required)
export OCP_NODE_BASTION="bastion ${OCP_NODE_BASTION_IP_ADDRESS}"
export OCP_NODE_HAPROXY="haproxy ${OCP_NODE_BASTION_IP_ADDRESS}"

#bootstrap and master nodes, hostname, IP and MAC required
export OCP_NODE_BOOTSTRAP="bootstrap 192.168.47.21 00:50:56:b3:0c:7b"
export OCP_NODE_MASTER_01="master2-01 192.168.47.22 00:50:56:b3:01:7d"
export OCP_NODE_MASTER_02="master2-02 192.168.47.23 00:50:56:b3:7a:6d"
export OCP_NODE_MASTER_03="master2-03 192.168.47.24 00:50:56:b3:1c:65"

#OCP worker nodes that are served by DNS and DHCP server
#hostname, IP and MAC required
#syntax: "<HOSTNAME> <IP> <MAC>; <HOSTNAME> <IP> <MAC>;"
#where hostname, ip and mac are separated by space and followed by ;
#note: if OCP_THREE_NODE_CLUSTER is yes, then this variable is ignored
export OCP_NODE_WORKER_HOSTS=" \
worker-01 192.168.47.111 00:50:56:b3:93:4f; \
worker-02 192.168.47.112 00:50:56:b3:33:f1; \
worker-03 192.168.47.113 00:50:56:b3:7e:23; \
"
#hosts used in HAProxy configuration
#these are configured in HAProxy to receive workload requests
#use all worker nodes or chosen worker if 
#note: if OCP_THREE_NODE_CLUSTER is yes, then this variable is ignored
export OCP_HAPROXY_WORKER_HOSTS=" \
worker-01 192.168.47.111 00:50:56:b3:93:4f; \
worker-02 192.168.47.112 00:50:56:b3:33:f1; \
"

#hosts that are not OCP worker nodes but need to be in DNS and DHCP
#syntax: "<HOSTNAME> <IP> <MAC>; <HOSTNAME> <IP> <MAC>;"
#where hostname, ip and mac are separated by space and followed by ;
export OCP_OTHER_HOSTS_DHCP=" \
dummy-test 192.168.47.254 DE:AD:C0:DE:CA:FE;\
test-bootstrap 192.168.47.200 00:50:56:b3:4d:f4; \
"

#other hosts in the OCP environment these are in DNS but not in DHCP
#syntax: "<HOSTNAME> <IP>; <HOSTNAME> <IP>;"
export OCP_OTHER_DNS_HOSTS=" \
mirror-registry 192.168.47.100; \
registry 192.168.47.100; \
ocp-registry 192.168.47.100; \
external-registry 192.168.47.100;\
"

#DNS config
#OCP_DNS_FORWARDERS format: <ip>;<ip>; (semicolon separated list of DNS servers)"
export OCP_DNS_FORWARDERS="10.31.0.10;10.31.11.10;"
#OC_DNS_ALLOWED_NETWORKS format: ip/mask;ip/mask; (semicolon separated list of networks)"
export OCP_DNS_ALLOWED_NETWORKS="127.0.0.0/8;10.0.0.0/8;192.0.0.0/8;172.0.0.0/8;"

#Network information for DHCP server
#network interface that is used by DHCP, this interface is in the host where DHCP container is running
#make sure to set DHCP network interface to correct interface
export OCP_DHCP_NETWORK_INTERFACE=ens224
export OCP_DHCP_NETWORK=192.168.47.0
export OCP_DHCP_NETWORK_MASK=255.255.255.0
export OCP_DHCP_NETWORK_BROADCAST_ADDRESS=192.168.47.255
#if having more than one router, NTP or DNS server, separate them using comma ','
export OCP_DHCP_NETWORK_ROUTER=192.168.47.1
export OCP_DHCP_NTP_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}
export OCP_DHCP_DNS_SERVER=${OCP_NODE_BASTION_IP_ADDRESS}

#PXE variables, RHCOS files
export OCP_PXE_RHCOS_KERNEL_URL=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/rhcos/rhcos-${OCP_RHCOS_VERSION}-x86_64-live-kernel-x86_64
export OCP_PXE_RHCOS_INITRAMFS_URL=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/rhcos/rhcos-${OCP_RHCOS_VERSION}-x86_64-live-initramfs.x86_64.img
export OCP_PXE_RHCOS_ROOTFS_URL=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/rhcos/rhcos-${OCP_RHCOS_VERSION}-x86_64-live-rootfs.x86_64.img

#Ignition files
export OCP_IGNITION_URL_BOOTSTRAP=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/ignition/bootstrap.ign
export OCP_IGNITION_URL_MASTER=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/ignition//master.ign
export OCP_IGNITION_URL_WORKER=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/ignition//worker.ign
