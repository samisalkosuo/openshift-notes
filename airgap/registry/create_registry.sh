#!/bin/bash

#this script creates directory, service file and other for container registry

function usageEnv
{
  echo "$1 env variable missing."
  exit 1
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usageEnv OCP_DOMAIN
fi

if [[ "$OCP_MIRROR_REGISTRY_PORT" == "" ]]; then
  usageEnv OCP_MIRROR_REGISTRY_PORT
fi

if [[ "$OCP_SERVICE_NAME_MIRROR_REGISTRY" == "" ]]; then
  usageEnv OCP_SERVICE_NAME_MIRROR_REGISTRY
fi

if [[ "$OCP_MIRROR_REGISTRY_DIRECTORY" == "" ]]; then
  usageEnv OCP_MIRROR_REGISTRY_DIRECTORY
fi

if [[ "$OCP_MIRROR_REGISTRY_USER_NAME" == "" ]]; then
  usageEnv OCP_MIRROR_REGISTRY_USER_NAME
fi

if [[ "$OCP_MIRROR_REGISTRY_USER_PASSWORD" == "" ]]; then
  usageEnv OCP_MIRROR_REGISTRY_USER_PASSWORD
fi

set -e


function usage
{
  echo "Usage: $0 <REGISTRY_CRT_FILE_PATH> <REGISTRY_KEY_FILE_PATH>"
  exit 1
}


if [[ "$1" == "" ]]; then
  echo "Registry certificate file path is missing."
  usage
fi

if [[ "$2" == "" ]]; then
  echo "Registry certificate key file path is missing."
  usage
fi

#variables from args
__registry_name=$OCP_SERVICE_NAME_MIRROR_REGISTRY
__registry_dir=$OCP_MIRROR_REGISTRY_DIRECTORY
__registry_user_name=$OCP_MIRROR_REGISTRY_USER_NAME
__registry_user_password=$OCP_MIRROR_REGISTRY_USER_PASSWORD
__registry_port=$OCP_MIRROR_REGISTRY_PORT
__registry_crt_file=$1
__registry_key_file=$2

#create registry directories
mkdir -p ${__registry_dir}/{auth,certs,data}

#create registry user to registry dir
htpasswd -bBc ${__registry_dir}/auth/htpasswd ${__registry_user_name} ${__registry_user_password}

#certificate and key file are copied to registry certs-dire as domain.crt and domain.key
cp ${__registry_crt_file} ${__registry_dir}/certs/domain.crt
cp ${__registry_key_file} ${__registry_dir}/certs/domain.key

echo "Creating service file..."
#create service file
__service_file=${__registry_name}.service
cp registry.service.template ${__service_file}

#change values service file
#note sed delimiter is ! instead of /
sed -i s!%SERVICE_NAME%!${__registry_name}!g ${__service_file}
sed -i s!%REGISTRY_DIR%!${__registry_dir}!g ${__service_file}
sed -i s!%REGISTRY_PORT%!${__registry_port}!g ${__service_file}

echo "Service file created. Copying it to /etc/systemd/system/"
cp ${__service_file} /etc/systemd/system/

echo "Starting ${__registry_name} service..."
systemctl start ${__registry_name}
#sleeping 3 seconds so that registry starts..
sleep 3

echo "adding \"127.0.01  mirror-registry.${OCP_DOMAIN}\" to /etc/hosts..."
echo "127.0.0.1 mirror-registry.${OCP_DOMAIN}" >> /etc/hosts

echo "Use following commands to interact with the registry:"
echo "  " systemctl start ${__registry_name}
echo "  " systemctl stop ${__registry_name}
echo "  " systemctl restart ${__registry_name}
echo "  " systemctl status ${__registry_name}
echo "  " systemctl enable ${__registry_name}
echo ""
echo "Testing registry using command: curl -u ${__registry_user_name}:${__registry_user_password} https://mirror-registry.${OCP_DOMAIN}:${__registry_port}/v2/_catalog"
curl -u ${__registry_user_name}:${__registry_user_password} -k https://mirror-registry.${OCP_DOMAIN}:${__registry_port}/v2/_catalog
