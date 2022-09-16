#Env variables for UPI OpenShift install

#pull-secret
export OMG_OCP_PULL_SECRET_FILE=/root/pull-secret.json

#if installing with proxy
#uncomment and edit following variables
#export OMG_OCP_HTTP_PROXY=
#export OMG_OCP_HTTPS_PROXY=
#export OMG_OCP_NO_PROXY=

#OCP version to install/upgrade
#check https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
#for desired version 
export OMG_OCP_VERSION=4.10.30

#Red Hat mirror registry
#check latest version
#https://developers.redhat.com/content-gateway/rest/mirror2/pub/openshift-v4/clients/mirror-registry/
export OMG_REDHAT_MIRROR_REGISTRY_VERSION=1.2.4

#OpenShift domain
export OMG_OCP_DOMAIN=local.net
#OpenShift cluster name
export OMG_OCP_CLUSTER_NAME=ocp

#network CIDR for OCP nodes, used in install-config.yaml
export OMG_OCP_NODE_NETWORK_CIDR=1.2.15.0/24

#set this variable is cluster is only three nodes (that is, 3 masters)
#use values 'yes' or 'no'
export OMG_OCP_THREE_NODE_CLUSTER=no

#OpenShift nodes
#bootstrap and master nodes that are served by DNS and DHCP server
#hostname, IP and MAC required
export OMG_OCP_NODE_BOOTSTRAP="bootstrap 1.2.15.10 00:50:56:b3:ad:48"
export OMG_OCP_NODE_MASTER_01="master1 1.2.15.11 00:50:56:b3:64:81"
export OMG_OCP_NODE_MASTER_02="master2 1.2.15.12 00:50:56:b3:8c:b2"
export OMG_OCP_NODE_MASTER_03="master3 1.2.15.13 00:50:56:b3:ce:11"

#OCP worker nodes that are served by DNS and DHCP server
#hostname, IP and MAC required
#syntax: "<HOSTNAME> <IP> <MAC>; <HOSTNAME> <IP> <MAC>;"
#where hostname, ip and mac are separated by space and followed by ;
#note: if OMG_OCP_THREE_NODE_CLUSTER is yes, then this variable is ignored
#note: if not using three node cluster, at least two workers are required
#the first two workers are used as router hosts and configured in load balancer
export OMG_OCP_NODE_WORKER_HOSTS=" \
worker01 1.2.15.14 00:50:56:b3:b8:3b   ; \
worker02 1.2.15.15 00:50:56:b3:a4:01   ; \
worker03 1.2.15.16 00:50:56:b3:cf:91   ; \
worker04 1.2.15.17 00:50:56:b3:d6:35   ; \
worker05 1.2.15.18 00:50:56:b3:96:3c    ; \
worker06 1.2.15.19 00:50:56:b3:6f:ed   ; \
storage01 1.2.15.20 00:50:56:b3:f7:98   ; \
storage02 1.2.15.21 00:50:56:b3:75:58   ; \
storage03 1.2.15.22 00:50:56:b3:27:4a    ; \
"

#mirror registry hostname and IP, added to DNS
export OMG_OCP_MIRROR_REGISTRY_HOST_NAME=registry
export OMG_OCP_MIRROR_REGISTRY_IP=1.2.15.2
export OMG_OCP_MIRROR_REGISTRY_PORT=443

#load balancer: hostname and IP
#added to DNS
export OMG_OCP_LOADBALANCER_HOST_NAME="lb"
export OMG_OCP_LOADBALANCER_IP="1.2.15.1"

#other hosts in the OCP environment
#these are in DNS but not in DHCP
#syntax: "<HOSTNAME> <IP>; <HOSTNAME> <IP>;"
export OMG_OCP_OTHER_DNS_HOSTS=" \
${OMG_OCP_LOADBALANCER_HOST_NAME} ${OMG_OCP_LOADBALANCER_IP}  ; \
${OMG_OCP_MIRROR_REGISTRY_HOST_NAME} ${OMG_OCP_MIRROR_REGISTRY_IP}  ; \
"

#DNS server IP, address. could be bastion, if setting up DNS locally
export OMG_DNS_SERVER_IP=1.2.15.2

#DNS forwarders, space separated list of DNS servers"
export OMG_DNS_FORWARDERS="8.8.8.8 8.8.4.4"

#NTP server IP address, used when setting up DHCP
export OMG_NTP_SERVER_IP=1.2.15.2

#Apache host and port, used to setup PXE
#should be the same as DHCP server
export OMG_OCP_APACHE_HOST=1.2.15.2
export OMG_OCP_APACHE_PORT=8080

#DHCP config
#OpenShift nodes specified above are added to DHCP configuration

#dhcp server ip address, this is typically bastion but can be other server
export OMG_OCP_DHCP_SERVER_IP_ADDRESS=1.2.15.2

#Network information for DHCP server
#network interface that is used by DHCP, this interface is in the host where DHCP container is running
#make sure to set DHCP network interface to correct interface
export OMG_OCP_DHCP_NETWORK_INTERFACE=ens224
export OMG_OCP_DHCP_NETWORK=1.2.15.0
export OMG_OCP_DHCP_NETWORK_MASK=255.255.255.0
export OMG_OCP_DHCP_NETWORK_BROADCAST_ADDRESS=1.2.15.255
#if having more than one router, NTP or DNS server, separate them using comma ','
export OMG_OCP_DHCP_NETWORK_ROUTER=1.2.3.1
export OMG_OCP_DHCP_NTP_SERVER=${OMG_NTP_SERVER_IP}
export OMG_OCP_DHCP_DNS_SERVER=${OMG_DNS_SERVER_IP}
#DHCP server range to dynamically give IP address
#usedin OpenShift IPI installation
#export OMG_OCP_DHCP_IP_RANGE="192.168.47.190 192.168.47.240"

#packages from dnf repository
export OMG_PREREQ_PACKAGES=" \
jq \
podman \
container* \
nmap \
bash-completion \
httpd-tools \
curl \
wget \
tcpdump \
dnsmasq \
haproxy \
tmux \
openldap \
openldap-clients \
openldap-devel \
net-tools \
nfs-utils \
python3 \
git \
httpd \
ntpstat \
chrony \
bind \
bind-utils \
dhcp-server \
dhcp-client \
expect \
ansible \
ntfs-3g \
unzip \
skopeo \
syslinux \
haproxy \
yum-utils \
createrepo \
libmodulemd \
modulemd-tools \
cloud-utils-growpart \
gdisk \
"
