#!/bin/sh

#setup HAProxy load balancer

if [[ "$OMG_OCP_NODE_BOOTSTRAP" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

function configureHAProxy 
{
    echo "Configuring and starting HAProxy..."

    #get bootstrap and master IPs
    local bootstrap=($OMG_OCP_NODE_BOOTSTRAP)
    local master1=($OMG_OCP_NODE_MASTER_01)
    local master2=($OMG_OCP_NODE_MASTER_02)
    local master3=($OMG_OCP_NODE_MASTER_03)
    local bootstrapIP=${bootstrap[1]}
    local master1IP=${master1[1]}
    local master2IP=${master2[1]}
    local master3IP=${master3[1]}
    #get the first two worker node IPs
    local var=$OMG_OCP_NODE_WORKER_HOSTS
    local SAVEIFS=$IFS   # Save current IFS
    IFS=$';'      # Change IFS to ;
    local arr=($var) # split to array 
    IFS=$SAVEIFS   # Restore IFS    
    local worker1=(${arr[0]})
    local worker2=(${arr[1]})
    local worker1_IP=${worker1[1]}
    local worker2_IP=${worker2[1]}

    #if virtual IP is specified, assume IPI install
    #and set virtual IPs as master and workers
    if [[ "$OMG_OCP_VSPHERE_VIRTUAL_IP_API" != "" ]]; then
        bootstrapIP=$OMG_OCP_VSPHERE_VIRTUAL_IP_API
        master1IP=$OMG_OCP_VSPHERE_VIRTUAL_IP_API
        master2IP=$OMG_OCP_VSPHERE_VIRTUAL_IP_API
        master3IP=$OMG_OCP_VSPHERE_VIRTUAL_IP_API
        worker1_IP=$OMG_OCP_VSPHERE_VIRTUAL_IP_INGRESS
        worker2_IP=$OMG_OCP_VSPHERE_VIRTUAL_IP_INGRESS
    fi


    cat > /etc/haproxy/haproxy.cfg << EOF
#Sample haproxy config from 
#https://access.redhat.com/articles/5127211

# Before using set SELinux
# setsebool -P haproxy_connect_any=1
#

#---------------------------------------------------------------------
# See the full configuration options online.
#
#   https://www.haproxy.org/download/1.8/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

    # utilize system-wide crypto-policies
    #ssl-default-bind-ciphers PROFILE=SYSTEM
    #ssl-default-server-ciphers PROFILE=SYSTEM

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    tcp
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------

frontend api
    bind 0.0.0.0:6443
    default_backend controlplaneapi

frontend apiinternal
    bind 0.0.0.0:22623
    default_backend controlplaneapiinternal

frontend secure
    bind 0.0.0.0:443
    default_backend secure

frontend insecure
    bind 0.0.0.0:80
    default_backend insecure

#---------------------------------------------------------------------
# static backend
#---------------------------------------------------------------------

backend controlplaneapi
    balance source
    server bootstrap $bootstrapIP:6443 check     # Can be removed or commented out after install completes
    server master1 $master1IP:6443 check
    server master2 $master2IP:6443 check
    server master3 $master3IP:6443 check

backend controlplaneapiinternal
    balance source
    server bootstrap $bootstrapIP:22623 check     # Can be removed or commented out after install completes
    server master1 $master1IP:22623 check
    server master2 $master2IP:22623 check
    server master3 $master3IP:22623 check

backend secure
    balance source
    server worker1 $worker1_IP:443 check
    server worker2 $worker2_IP:443 check

backend insecure
    balance source
    server worker1 $worker1_IP:80 check
    server worker2 $worker2_IP:80 check
EOF
    
    #echo $HAPROXY_CONFIG > /etc/haproxy/haproxy.cfg

    setsebool -P haproxy_connect_any=1

    systemctl enable haproxy
    systemctl restart haproxy

    # echo "Open HTTP/HTTPS ports..."
    # firewall-cmd --add-port=80/tcp --add-port=443/tcp --add-port=8080/tcp 
    # echo "Open OpenShift API ports..."
    # firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 
    # firewall-cmd --runtime-to-permanent
    
    echo "Configuring and starting HAProxy...done."

}

configureHAProxy

