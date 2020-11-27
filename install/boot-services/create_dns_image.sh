#!/bin/bash


function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi

if [[ "$OCP_DNS_FORWARDERS" == "" ]]; then
  usage OCP_DNS_FORWARDERS
fi

if [[ "$OCP_DNS_ALLOWED_NETWORKS" == "" ]]; then
  usage OCP_DNS_ALLOWED_NETWORKS
fi

if [[ "$OCP_SERVICE_NAME_DNS_SERVER" == "" ]]; then
  usage OCP_SERVICE_NAME_DNS_SERVER
fi

__name=$OCP_SERVICE_NAME_DNS_SERVER

set -e

__named_conf=dns/named.conf
echo "Creating named.conf..."

#modify named.conf
cp dns/named.conf.template ${__named_conf}

sed -i s!%DNSSERVERS%!${OCP_DNS_FORWARDERS}!g ${__named_conf}
sed -i s!%ALLOWED_NETWORKS%!${OCP_DNS_ALLOWED_NETWORKS}!g ${__named_conf}
sed -i s!%OCP_DOMAIN%!${OCP_DOMAIN}!g ${__named_conf}

echo "Creating $OCP_DOMAIN zone file..."
sh dns/create_zone_file.sh

echo "Building ${__name} image..."

podman build --build-arg OCP_DOMAIN=${OCP_DOMAIN} -t ${__name} ./dns

echo "Creating service file for ${__name} image..."
__service_file=dns/${__name}.service
cp dns/dns.service.template ${__service_file}

sed -i s!%SERVICE_NAME%!${__name}!g ${__service_file}

cp ${__service_file} /etc/systemd/system/
echo "Service file created and copied to /etc/systemd/system/"
systemctl daemon-reload


echo "Use following commands to interact with the registry:"
echo "  " systemctl start ${__name}
echo "  " systemctl stop ${__name}
echo "  " systemctl restart ${__name}
echo "  " systemctl status ${__name}
echo "  " systemctl enable ${__name}
