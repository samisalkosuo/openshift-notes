#!/bin/bash

function usage
{
  echo "$1 env variable missing."
  exit 1  
}

#use any argument to NOT include bootstrap
if [[ "$1" == "" ]]; then
  if [[ "$OCP_NODE_BOOTSTRAP" == "" ]]; then
    usage OCP_NODE_BOOTSTRAP
  fi
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

if [[ "$OCP_NODE_WORKER_HOSTS" == "" ]]; then
  usage OCP_NODE_WORKER_HOSTS
fi

if [[ "$OCP_SERVICE_NAME_HAPROXY_SERVER" == "" ]]; then
  usage OCP_SERVICE_NAME_HAPROXY_SERVER
fi


__name=$OCP_SERVICE_NAME_HAPROXY_SERVER
__haproxy_cfg=haproxy.cfg

set -e

cp haproxy.cfg.template $__haproxy_cfg

echo "" >> $__haproxy_cfg
echo "backend master-api-be" >> $__haproxy_cfg
echo "    balance roundrobin" >> $__haproxy_cfg
echo "    mode tcp" >> $__haproxy_cfg

function addEntry
{
  local __port=$2
   echo $1 | awk -v port="${__port}" -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":" port " check\" >> " file}' | sh
}

if [[ "$1" == "" ]]; then
  addEntry "$OCP_NODE_BOOTSTRAP" 6443
fi
addEntry "$OCP_NODE_MASTER_01" 6443
addEntry "$OCP_NODE_MASTER_02" 6443
addEntry "$OCP_NODE_MASTER_03" 6443

echo "" >> $__haproxy_cfg
echo "backend master-api-2-be" >> $__haproxy_cfg
echo "    balance roundrobin" >> $__haproxy_cfg
echo "    mode tcp" >> $__haproxy_cfg

if [[ "$1" == "" ]]; then
  addEntry "$OCP_NODE_BOOTSTRAP" 22623
fi
addEntry "$OCP_NODE_MASTER_01" 22623
addEntry "$OCP_NODE_MASTER_02" 22623
addEntry "$OCP_NODE_MASTER_03" 22623


echo "" >> $__haproxy_cfg
echo "backend openshift-app-https" >> $__haproxy_cfg
echo "    balance roundrobin" >> $__haproxy_cfg
echo "    mode tcp" >> $__haproxy_cfg
echo  $OCP_NODE_WORKER_HOSTS  | sed "s/;/\n/g" | awk -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":443 check\"" " >> " file}' | sh

echo "" >> $__haproxy_cfg
echo "backend openshift-app-http" >> $__haproxy_cfg
echo "    balance roundrobin" >> $__haproxy_cfg
echo "    mode tcp" >> $__haproxy_cfg
echo  $OCP_NODE_WORKER_HOSTS  | sed "s/;/\n/g" | awk -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":80 check\"" " >> " file}'  | sh

echo "Building $__name container..."
podman build -t $__name .

__service_file=${__name}.service
cp haproxy.service.template ${__service_file}
#change values service file
sed -i s/%SERVICE_NAME%/${__name}/g ${__service_file}

cp ${__service_file} /etc/systemd/system/
echo "Service file created and copied to /etc/systemd/system/"
systemctl daemon-reload

echo "Use following commands to interact with the registry:"
echo "  " systemctl start ${__name}
echo "  " systemctl stop ${__name}
echo "  " systemctl restart ${__name}
echo "  " systemctl status ${__name}
echo "  " systemctl enable ${__name}

echo verify configuration:
echo podman run -it --rm --name haproxy-syntax-check $__name haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
