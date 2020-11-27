#!/bin/bash

set -e

function usage
{
  echo "$1 env variable missing."
  exit 1
}

if [[ "$OCP_SERVICE_NAME_NTP_SERVER" == "" ]]; then
  usage OCP_SERVICE_NAME_NTP_SERVER
fi

__name=$OCP_SERVICE_NAME_NTP_SERVER

echo "Building $__name container..."
podman build -t ${__name} .
__service_file=${__name}.service
cp ntp-server.service.template ${__service_file}

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

