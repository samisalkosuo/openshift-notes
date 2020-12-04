#omg.sh service related functions and commands

function serviceOperation
{
  local op=$1
  local svc=$2  
  set +e
  ls /etc/systemd/system/${svc}* &> /dev/null
  if [ $? -eq 0 ];  then
    #service exists, do operation
    echo "$op $svc service..."
    local __options=""
    if [[ "$op" == "status" ]]; then
      __options=--no-pager
    fi

    systemctl $__options $op $svc
  else
    echo "service $svc does not exist"
  fi
  set -e
}

function doServiceOperation
{
  local __systemctlOperation=$1
  local __role=jump_and_bastion

  if [[ "$OCP_OMG_SERVER_ROLE" == "haproxy" ]]; then
    __role=haproxy
  fi

  if [[ "$__role" == "jump_and_bastion" ]]; then
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_APACHE_RHCOS
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_APACHE_IGNITION
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_MIRROR_REGISTRY
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_NTP_SERVER
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_DNS_SERVER
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_DHCPPXE_SERVER
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_EXTERNAL_REGISTRY
  fi
  
  if [[ "$__role" == "haproxy" ]]; then
    serviceOperation ${__systemctlOperation} $OCP_SERVICE_NAME_HAPROXY_SERVER
  fi

}

if [[ "${__operation}" == "svc-start" ]]; then
  doServiceOperation start
fi

if [[ "${__operation}" == "svc-stop" ]]; then
  doServiceOperation stop
fi

if [[ "${__operation}" == "svc-enable" ]]; then
  doServiceOperation enable
fi

if [[ "${__operation}" == "svc-disable" ]]; then
  doServiceOperation disable
fi

if [[ "${__operation}" == "svc-status" ]]; then
  doServiceOperation status
fi
