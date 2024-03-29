#!/bin/sh

#setup Gobetween load balancer

if [[ "$OMG_OCP_NODE_BOOTSTRAP" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

__default_healtcheck="""fails = 1 
passes = 1 
interval = \"3s\" 
timeout=\"1s\" 
kind = \"ping\" 
ping_timeout_duration = \"500ms\" 
"""

__gobetween_cfg_dir=/etc/gobetween
mkdir -p $__gobetween_cfg_dir
__gobetween_cfg_file=$__gobetween_cfg_dir/config.toml

function setupLoadBalancer
{
    #configuring gobetween load balancer
    #https://github.com/yyyar/gobetween
    echo "Configuring Gobetween..."
    createGobetweenConfigurationFileUPI
    
    setupGobetweenService
    echo "Configuring Gobetween...done."

}

function setupGobetweenService
{
        #service file
    cat > /etc/systemd/system/gobetween.service << EOF
[Unit]
Description=Gobetween - modern LB for cloud era
Documentation=https://github.com/yyyar/gobetween/wiki
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=simple
PIDFile=/run/gobetween.pid
ExecStart=/usr/local/bin/gobetween -c /etc/gobetween/config.toml --pidfile /run/gobetween.pid
PrivateTmp=true
LimitNOFILE=infinity
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo "Starting and enabling Gobetween loadbalancer..."
    systemctl daemon-reload
    systemctl enable gobetween
    systemctl restart gobetween
}


function createGobetweenConfigurationFileUPI
{
    echo "Creating config file ${__gobetween_cfg_file}"
    local api1Discovery=""
    local api2Discovery=""
    local bootstrap=($OMG_OCP_NODE_BOOTSTRAP)
    local master1=($OMG_OCP_NODE_MASTER_01)
    local master2=($OMG_OCP_NODE_MASTER_02)
    local master3=($OMG_OCP_NODE_MASTER_03)
    local bootstrap6443=""
    local bootstrap22623=""
    if [[ "${OMG_OCP_BOOTSTRAP_COMPLETE}" != "yes" ]]; then
      bootstrap6443="\"${bootstrap[1]}:6443 weight=1\","
      bootstrap22623="\"${bootstrap[1]}:22623 weight=1\","
    fi
    api1Discovery="""
   ${bootstrap6443}
   \"${master1[1]}:6443 weight=1\",
   \"${master2[1]}:6443 weight=1\",
   \"${master3[1]}:6443 weight=1\"
"""
    api2Discovery="""
   ${bootstrap22623}
   \"${master1[1]}:22623 weight=1\",
   \"${master2[1]}:22623 weight=1\",
   \"${master3[1]}:22623 weight=1\"
"""
    
    local httpDiscovery=""
    local httpsDiscovery=""

    local var=$OMG_OCP_NODE_WORKER_HOSTS
    local SAVEIFS=$IFS   # Save current IFS
    IFS=$';'      # Change IFS to ;
    local arr=($var) # split to array 
    IFS=$SAVEIFS   # Restore IFS    
    local worker1=(${arr[0]})
    local worker2=(${arr[1]})
    
    httpDiscovery="""
   \"${worker1[1]}:80 weight=1\",
   \"${worker2[1]}:80 weight=1\"
"""
    httpsDiscovery="""
   \"${worker1[1]}:443 weight=1\",
   \"${worker2[1]}:443 weight=1\"
"""

    #if virtual IP is specified, assume IPI install
    #and set virtual IPs as master and workers
    if [[ "$OMG_OCP_VSPHERE_VIRTUAL_IP_API" != "" ]]; then
        api1Discovery="""
    \"${OMG_OCP_VSPHERE_VIRTUAL_IP_API}:6443 weight=1\"
    """
        api2Discovery="""
    \"${OMG_OCP_VSPHERE_VIRTUAL_IP_API}:22623 weight=1\"
    """
        httpDiscovery="""
    \"${OMG_OCP_VSPHERE_VIRTUAL_IP_INGRESS}:80 weight=1\"
    """
        httpsDiscovery="""
    \"${OMG_OCP_VSPHERE_VIRTUAL_IP_INGRESS}:443 weight=1\"
    """
    fi




    cat > ${__gobetween_cfg_file} << EOF
#http://gobetween.io/documentation.html

[logging]
level = "info"    # "debug" | "info" | "warn" | "error"
output = "stdout" # "stdout" | "stderr" | "/path/to/gobetween.log"
format = "text"   # (optional) "text" | "json"

#
# Metrics server configuration
#
[metrics]
enabled = false # false | true
bind = ":9284"  # "host:port"

[defaults]
protocol = "tcp"
balance = "roundrobin"
max_connections = 10000
client_idle_timeout = "10m"
backend_idle_timeout = "10m"
backend_connection_timeout = "2s"

[servers.openshift-api1]
bind = "0.0.0.0:6443"

[servers.openshift-api1.discovery]
kind = "static"
static_list = [
${api1Discovery}
]

[servers.openshift-api2]
bind = "0.0.0.0:22623"

[servers.openshift-api2.discovery]
kind = "static"
static_list = [
${api2Discovery}
]

[servers.openshift-http]
bind = "0.0.0.0:80"

[servers.openshift-http.discovery]
kind = "static"
static_list = [
${httpDiscovery}
]

[servers.openshift-https]
bind = "0.0.0.0:443"

[servers.openshift-https.discovery]
kind = "static"
static_list = [
${httpsDiscovery}
]

#healtchecks
[servers.openshift-api1.healthcheck]
${__default_healtcheck}

[servers.openshift-api2.healthcheck]
${__default_healtcheck}

[servers.openshift-http.healthcheck]
${__default_healtcheck}

[servers.openshift-https.healthcheck]
${__default_healtcheck}

EOF

}

setupLoadBalancer
