#!/bin/bash

# this script generates registry cert using self-signed CA cert and key

function usage
{
  echo "$1 env variable missing."
  exit 1  
}

if [[ "$OCP_DOMAIN" == "" ]]; then
  usage OCP_DOMAIN
fi

__domain=$OCP_DOMAIN

__validity_days=3650
__base_name=registry
__common_name=${__base_name}.${__domain}
__alt_names=(mirror-registry ocp-registry ocp-registry2 operator-registry external-registry external-registry2 registry1 registry2 registry3 registry4 registry5)
__current_dir=$(pwd)

set -e

__csr_file=${__base_name}_csr.txt
cat > ${__csr_file} << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = req_ext
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=FI
O=TopSecret
emailAddress=mr.smith@${__domain}
CN = ${__common_name}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${__base_name}
DNS.2 = ${__common_name}
DNS.3 = ${__common_name}.local
EOF

position=3

for ((i = 0; i < ${#__alt_names[@]}; ++i)); do
  # bash arrays are 0-indexed
   position=$(( $position + 1 ))
   name=${__alt_names[$i]}
   echo "DNS.$position  = $name" >> ${__csr_file}
   position=$(( $position + 1 ))
   echo "DNS.$position  = $name.${__domain}" >> ${__csr_file}
   position=$(( $position + 1 ))
   echo "DNS.$position  = $name.${__domain}.local" >> ${__csr_file}
 done

#create registry certificate key:
openssl genrsa -out ${__base_name}.key 4096

#create CSR:  
openssl req -new -sha256 -key ${__base_name}.key -out ${__base_name}.csr -config ${__csr_file}

#sign CSR usign CA cert
openssl x509 -req \
             -extfile ${__csr_file} \
             -extensions req_ext \
             -in ${__base_name}.csr \
             -CA CA_${__domain}.crt \
             -CAkey CA_${__domain}.key  \
             -CAcreateserial \
             -out ${__base_name}.crt \
             -days ${__validity_days} \
             -sha256 

#combine CA and registry certs
cat ${__base_name}.crt CA_${__domain}.crt > domain.crt
cp ${__base_name}.key domain.key

echo "Registry certificate created"
echo "View it using command:"
echo "  openssl x509 -in ${__current_dir}/${__base_name}.crt -text -noout"
echo ""
echo "Use following files as registry certificate:"
echo "  ${__current_dir}/domain.crt"
echo "  ${__current_dir}/domain.key"
