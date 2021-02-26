
__haproxy_cfg=${__omg_runtime_dir}/haproxy.cfg


function configureHAProxy
{
  echo "Configuring HAProxy..."

  #if local_repository directory is present => assume standalone haproxy server without Red Hat repository
  #install haproxy from local repository
  if [ -d local_repository ]; then
    echo "local_repository directory exists, creating local repository and installing haproxy..."
    createLocalRepository
    dnf -y install haproxy
  fi

  #backup existing config file, if not already copied
  if [ ! -f /etc/haproxy/haproxy.cfg.original ]; then
    cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.original
  fi

  cp templates/haproxy.cfg.template ${__haproxy_cfg}
  echo "" >> $__haproxy_cfg
  echo "backend master-api-be" >> $__haproxy_cfg
  echo "    balance roundrobin" >> $__haproxy_cfg
  echo "    mode tcp" >> $__haproxy_cfg

  if [[ "$OCP_NODE_HAPROXY_ADD_BOOTSTRAP" == "yes" ]]; then
    addEntry "$OCP_NODE_BOOTSTRAP" 6443
  fi
  addEntry "$OCP_NODE_MASTER_01" 6443
  addEntry "$OCP_NODE_MASTER_02" 6443
  addEntry "$OCP_NODE_MASTER_03" 6443

  echo "" >> $__haproxy_cfg
  echo "backend master-api-2-be" >> $__haproxy_cfg
  echo "    balance roundrobin" >> $__haproxy_cfg
  echo "    mode tcp" >> $__haproxy_cfg

  if [[ "$OCP_NODE_HAPROXY_ADD_BOOTSTRAP" == "yes" ]]; then
    addEntry "$OCP_NODE_BOOTSTRAP" 22623
  fi
  addEntry "$OCP_NODE_MASTER_01" 22623
  addEntry "$OCP_NODE_MASTER_02" 22623
  addEntry "$OCP_NODE_MASTER_03" 22623

  echo "" >> $__haproxy_cfg
  echo "backend openshift-app-https" >> $__haproxy_cfg
  echo "    balance roundrobin" >> $__haproxy_cfg
  echo "    mode tcp" >> $__haproxy_cfg
  #if not three node cluster, add OCP_HAPROXY_WORKER_HOSTS
  if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    echo  $OCP_HAPROXY_WORKER_HOSTS  | sed "s/;/\n/g" | awk -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":443 check\"" " >> " file}' | sh
  else
    #in three-node clusters add masters as workers to serve workloads
    addEntry "$OCP_NODE_MASTER_01" 443
    addEntry "$OCP_NODE_MASTER_02" 443
    addEntry "$OCP_NODE_MASTER_03" 443
  fi

  echo "" >> $__haproxy_cfg
  echo "backend openshift-app-http" >> $__haproxy_cfg
  echo "    balance roundrobin" >> $__haproxy_cfg
  echo "    mode tcp" >> $__haproxy_cfg
  #if not three node cluster, add OCP_HAPROXY_WORKER_HOSTS
  if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    echo  $OCP_HAPROXY_WORKER_HOSTS  | sed "s/;/\n/g" | awk -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":80 check\"" " >> " file}'  | sh
  else
    #in three-node clusters add masters as workers to serve workloads
    addEntry "$OCP_NODE_MASTER_01" 80
    addEntry "$OCP_NODE_MASTER_02" 80
    addEntry "$OCP_NODE_MASTER_03" 80
  fi

  echo "Configuring SELinux to allow any ports for HAProxy..." 
  setsebool -P haproxy_connect_any 1
  #copy created config file
  cp $__haproxy_cfg /etc/haproxy/haproxy.cfg
  echo "Starting and enabling HAProxy..."
  systemctl daemon-reload
  systemctl enable haproxy
  systemctl restart haproxy
        
  echo "Configuring HAProxy...done."

}

function addEntry
{
  local __port=$2
  echo $1 | awk -v port="${__port}" -v file="${__haproxy_cfg}" '$1{print "echo \"server " $1 " " $2 ":" port " check\" >> " file}' | sh
}

