#!/bin/bash

#this script creates Apache container that include RHCOS binaries


function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_RHCOS_MAJOR_RELEASE" == "" ]]; then
  usage OCP_RHCOS_MAJOR_RELEASE
fi

if [[ "$OCP_VERSION" == "" ]]; then
  usage OCP_VERSION
fi

if [[ "$OCP_APACHE_RHCOS_PORT" == "" ]]; then
  usage OCP_APACHE_RHCOS_PORT
fi

if [[ "$OCP_SERVICE_NAME_APACHE_RHCOS" == "" ]]; then
  usage OCP_SERVICE_NAME_APACHE_RHCOS
fi

__name=$OCP_SERVICE_NAME_APACHE_RHCOS
__architecture=x86_64

set -e

echo "Building ${__name}:${OCP_VERSION} image..."
podman build -t ${__name}:${OCP_VERSION} --build-arg OCP_RELEASE=${OCP_RHCOS_MAJOR_RELEASE} --build-arg OCP_VERSION=${OCP_VERSION}  ./apache


echo "Creating service file for ${__name}:${OCP_VERSION} image..."
__service_file=apache/${__name}.service
cp apache/apache.service.template ${__service_file}

sed -i s!%SERVICE_NAME%!${__name}!g ${__service_file}
sed -i s!%VERSION%!${OCP_VERSION}!g ${__service_file}
sed -i s!%PORT%!${OCP_APACHE_RHCOS_PORT}!g ${__service_file}

cp ${__service_file} /etc/systemd/system/
systemctl daemon-reload

echo "Service file created and copied to /etc/systemd/system/"

echo "Use following commands to interact with the registry:"
echo "  " systemctl start ${__name}
echo "  " systemctl stop ${__name}
echo "  " systemctl restart ${__name}
echo "  " systemctl status ${__name}
echo "  " systemctl enable ${__name}
