#!/bin/bash

#this script creates image registry.
#registry directory, registry configuration and systemd service are created.

set -e

function usage
{
  echo "Usage: $0 <REGISTRY_NAME> <REGISTRY_DIR> <REGISTRY_PORT> <REGISTRY_CRT_FILE_PATH> <REGISTRY_KEY_FILE_PATH>"
  echo "REGISTRY_NAME is the name of the systemd service."
  echo "REGISTRY_DIR is the full path to registry dir. It is created if it does not exist."
  echo "REGISTRY_PORT is registry port."
  echo "REGISTRY_CRT_FILE_PATH  is the full path to certificate file."
  echo "REGISTRY_KEY_FILE_PATH is the full path to certificate key file."
  exit 1
}


if [[ "$1" == "" ]]; then
  echo "Registry name is missing."
  usage
fi

if [[ "$2" == "" ]]; then
  echo "Registry directory is missing."
  usage
fi

if [[ "$3" == "" ]]; then
  echo "Registry port is missing."
  usage
fi

if [[ "$4" == "" ]]; then
  echo "Certificate is missing."
  usage
fi

if [[ "$5" == "" ]]; then
  echo "Certificate key is missing."
  usage
fi

#variables from args
__registry_name=$1
__registry_dir=$2
__registry_user_name=admin
__registry_user_password=passw0rd
__registry_port=$3
__registry_crt_file=$4
__registry_key_file=$5
__registry_host_name=localhost

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

echo "Use following commands to interact with the registry:"
echo "  " systemctl start ${__registry_name}
echo "  " systemctl stop ${__registry_name}
echo "  " systemctl restart ${__registry_name}
echo "  " systemctl status ${__registry_name}
echo "  " systemctl enable ${__registry_name}
echo ""
echo "Test registry using command: curl -u ${__registry_user_name}:${__registry_user_password} https://localhost:${__registry_port}/v2/_catalog"
