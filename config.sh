#Env variables for scripts, OCP, downloads,mirroring,etc.

#OCP_OMG_SERVER_ROLE tells omg.sh script what is the role of the server
#set OCP_OMG_SERVER_ROLE=jump when using server with access to internet
#set OCP_OMG_SERVER_ROLE=bastion when using bastion server
#set OCP_OMG_SERVER_ROLE=bastion_online when using bastion and online install 
#set OCP_OMG_SERVER_ROLE=haproxy when using haproxy server
export OCP_OMG_SERVER_ROLE=jump


#OpenShift install user, created in bastion server
export OCP_INSTALL_USER=ocp

#OCP_DOMAIN is your domain where OpenShift is installed
export OCP_DOMAIN=forum.fi.ibm.com
export OCP_CLUSTER_NAME=ocp-07

#Find correct RHCOS major release and version from
#https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/"
export OCP_MAJOR_RELEASE=4.6
export OCP_VERSION=4.6.1

export OCP_RELEASE="${OCP_VERSION}-x86_64"
export OCP_LOCAL_REPOSITORY='ocp/openshift4'
export OCP_PRODUCT_REPO='openshift-release-dev'
export OCP_RELEASE_NAME="ocp-release"

#systemd service names
export OCP_SERVICE_NAME_APACHE_RHCOS=ocp-apache-rhcos
export OCP_SERVICE_NAME_APACHE_IGNITION=ocp-apache-ignition
export OCP_SERVICE_NAME_MIRROR_REGISTRY=ocp-mirror-registry
export OCP_SERVICE_NAME_NTP_SERVER=ocp-ntp
export OCP_SERVICE_NAME_DNS_SERVER=ocp-dns
export OCP_SERVICE_NAME_DHCPPXE_SERVER=ocp-dhcp-pxe
export OCP_SERVICE_NAME_HAPROXY_SERVER=ocp-haproxy

#mirror registry config
export OCP_MIRROR_REGISTRY_HOST_NAME=mirror-registry
export OCP_MIRROR_REGISTRY_PORT=5000
export OCP_MIRROR_REGISTRY_DIRECTORY=/opt/mirror-registry
export OCP_MIRROR_REGISTRY_USER_NAME=admin
export OCP_MIRROR_REGISTRY_USER_PASSWORD=passw0rd

#host and port for Apache servers that hold RHCOS and ignition files
#typically bastion is the host
export OCP_APACHE_RHCOS_HOST=192.168.47.100
export OCP_APACHE_RHCOS_PORT=8080
export OCP_APACHE_IGNITION_HOST=192.168.47.100
export OCP_APACHE_IGNITION_PORT=8181

#OCP and other nodes

#network CIDR for OCP nodes, used in install-config.yaml
export OCP_NODE_NETWORK_CIDR=192.168.47.0/24

#bastion and haproxy hostname and IP (MAC is not required)
export OCP_NODE_BASTION="bastion 192.168.47.100"
export OCP_NODE_HAPROXY="haproxy 192.168.47.101"

#bootstrap and master nodes, hostname, IP and MAC required
export OCP_NODE_BOOTSTRAP="bootstrap 192.168.47.104 00:50:56:b3:f7:bc"
export OCP_NODE_MASTER_01="master-01 192.168.47.105 00:50:56:b3:87:0a"
export OCP_NODE_MASTER_02="master-02 192.168.47.106 00:50:56:b3:a9:f1"
export OCP_NODE_MASTER_03="master-03 192.168.47.107 00:50:56:b3:ff:a5"

#OCP worker nodes that are served by DNS and DHCP server 
#hostname, IP and MAC required
#syntax: "<HOSTNAME> <IP> <MAC>; <HOSTNAME> <IP> <MAC>;"
#where hostname, ip and mac are separated by space and followed by ;
export OCP_NODE_WORKER_HOSTS=" \
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
export OCP_DHCP_NETWORK_INTERFACE=ens192
export OCP_DHCP_NETWORK=192.168.47.0
export OCP_DHCP_NETWORK_MASK=255.255.255.0
export OCP_DHCP_NETWORK_BROADCAST_ADDRESS=192.168.47.255
#if having more than one router, NTP or DNS server, separate them using comma ','
export OCP_DHCP_NETWORK_ROUTER=192.168.47.99
export OCP_DHCP_NTP_SERVER=192.168.47.100
export OCP_DHCP_DNS_SERVER=192.168.47.100

#PXE variables, RHCOS files
export OCP_PXE_RHCOS_KERNEL_URL=http://${OCP_APACHE_RHCOS_HOST}:${OCP_APACHE_RHCOS_PORT}/rhcos-4.6.1-x86_64-live-kernel-x86_64
export OCP_PXE_RHCOS_INITRAMFS_URL=http://${OCP_APACHE_RHCOS_HOST}:${OCP_APACHE_RHCOS_PORT}/rhcos-4.6.1-x86_64-live-initramfs.x86_64.img
export OCP_PXE_RHCOS_ROOTFS_URL=http://${OCP_APACHE_RHCOS_HOST}:${OCP_APACHE_RHCOS_PORT}/rhcos-4.6.1-x86_64-live-rootfs.x86_64.img

#Ignition files
export OCP_IGNITION_URL_BOOTSTRAP=http://${OCP_APACHE_IGNITION_HOST}:${OCP_APACHE_IGNITION_PORT}/bootstrap.ign
export OCP_IGNITION_URL_MASTER=http://${OCP_APACHE_IGNITION_HOST}:${OCP_APACHE_IGNITION_PORT}/master.ign
export OCP_IGNITION_URL_WORKER=http://${OCP_APACHE_IGNITION_HOST}:${OCP_APACHE_IGNITION_PORT}/worker.ign

