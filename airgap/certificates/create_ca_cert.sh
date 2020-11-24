#!/bin/bash

# this script generates self-signed CA cert and key

function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi

__domain=$OCP_DOMAIN
__country_name=FI
__org_name=ORG
__current_dir=$(pwd)

cat > ca_cert_config.txt << EOF
[ req ]
prompt             = no
distinguished_name = dn

[ dn ]
# The bare minimum is probably a commonName
commonName = ${__domain}
countryName = ${__country_name}
organizationName = ${__org_name}

[ server_exts ]
basicConstraints=critical,CA:true
keyUsage=digitalSignature, cRLSign, keyCertSign
EOF

__ca_file_name=CA_${__domain}
openssl req -x509 -config ca_cert_config.txt -extensions server_exts -nodes -days 3650 -newkey rsa:4096 -keyout ${__ca_file_name}.key -out ${__ca_file_name}.crt

echo "Adding CA cert as trusted..."
cp ${__ca_file_name}.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
echo ""
echo "Certificate created"
echo "View certificate using command:"
echo "openssl x509 -in ${__current_dir}/${__ca_file_name}.crt -text -noout"

