#!/bin/bash

set -e

function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi

if [[ "$OCP_CLUSTER_NAME" == "" ]]; then
  usage OCP_CLUSTER_NAME
fi

if [[ "$OCP_NODE_HAPROXY" == "" ]]; then
  usage OCP_NODE_HAPROXY
fi

if [[ "$OCP_NODE_BOOTSTRAP" == "" ]]; then
  usage OCP_NODE_BOOTSTRAP
fi

if [[ "$OCP_NODE_MASTER_01" == "" ]]; then
  usage OCP_NODE_MASTER_01
fi

if [[ "$OCP_NODE_MASTER_02" == "" ]]; then
  usage OCP_NODE_MASTER_02
fi

if [[ "$OCP_NODE_MASTER_03" == "" ]]; then
  usage OCP_NODE_MASTER_03
fi

if [[ "$OCP_NODE_BASTION" == "" ]]; then
  usage OCP_NODE_BASTION
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

if [[ "$OCP_OTHER_DNS_HOSTS" == "" ]]; then
  usage OCP_OTHER_DNS_HOSTS
fi

#OCP_NODE_BASTION is also DNS server
__hostname_bastion=$(echo  $OCP_NODE_BASTION | awk '{print $1}')
__ip_bastion=$(echo  $OCP_NODE_BASTION | awk '{print $2}')
__hostname_haproxy=$(echo  $OCP_NODE_HAPROXY | awk '{print $1}')
__ip_haproxy=$(echo  $OCP_NODE_HAPROXY | awk '{print $2}')
__hostname_bootstrap=$(echo  $OCP_NODE_BOOTSTRAP | awk '{print $1}')
__ip_bootstrap=$(echo  $OCP_NODE_BOOTSTRAP | awk '{print $2}')
__hostname_master01=$(echo  $OCP_NODE_MASTER_01 | awk '{print $1}')
__ip_master01=$(echo  $OCP_NODE_MASTER_01 | awk '{print $2}')
__hostname_master02=$(echo  $OCP_NODE_MASTER_02 | awk '{print $1}')
__ip_master02=$(echo  $OCP_NODE_MASTER_02 | awk '{print $2}')
__hostname_master03=$(echo  $OCP_NODE_MASTER_03 | awk '{print $1}')
__ip_master03=$(echo  $OCP_NODE_MASTER_03 | awk '{print $2}')

__zone_file=dns/${OCP_DOMAIN}.zone

echo "\$ORIGIN ${OCP_DOMAIN}." >> $__zone_file
echo "\$TTL    14400" > $__zone_file
echo "@ IN SOA ns.${OCP_DOMAIN}. hostmaster.${OCP_DOMAIN}. (" >> $__zone_file
echo "  2020022306 ; serial" >> $__zone_file
echo "  3H ; refresh" >> $__zone_file
echo "  15 ; retry" >> $__zone_file
echo "  1w ; expire" >> $__zone_file
echo "  3h ; nxdomain ttl" >> $__zone_file
echo " )" >> $__zone_file
echo "@ IN NS ns.${OCP_DOMAIN}." >> $__zone_file

echo "\$ORIGIN ${OCP_DOMAIN}." >> $__zone_file
echo "ns                      IN  A  ${__ip_bastion}" >> $__zone_file
echo "hostmaster              IN  A  ${__ip_bastion}" >> $__zone_file
echo "bastion                 IN  A  ${__ip_bastion}" >> $__zone_file
echo "${__hostname_haproxy}   IN  A  ${__ip_haproxy}" >> $__zone_file
echo "${__hostname_bootstrap} IN  A  ${__ip_bootstrap}" >> $__zone_file
echo "${__hostname_master01}  IN  A  ${__ip_master01}" >> $__zone_file
echo "${__hostname_master02}  IN  A  ${__ip_master02}" >> $__zone_file
echo "${__hostname_master03}  IN  A  ${__ip_master03}" >> $__zone_file
#add records from env variables
#if three node cluster, ignore OCP_NODE_WORKER_HOSTS
if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
  echo $OCP_NODE_WORKER_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
fi
echo $OCP_OTHER_HOSTS_DHCP | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file
echo $OCP_OTHER_DNS_HOSTS | sed "s/;/\n/g" | awk '$1{print $1 " IN A " $2}' >> $__zone_file

echo "\$ORIGIN ${OCP_CLUSTER_NAME}.${OCP_DOMAIN}." >> $__zone_file
echo "api     IN  A      ${__ip_haproxy}" >> $__zone_file
echo "api-int IN  CNAME  api" >> $__zone_file

echo "\$ORIGIN apps.${OCP_CLUSTER_NAME}.${OCP_DOMAIN}." >> $__zone_file
echo "*       IN  A      ${__ip_haproxy}" >> $__zone_file


