#!/bin/bash

#Default environment variables for self signed cert
SELFSIGNEDCERT_COUNTRY=FI
SELFSIGNEDCERT_ORGANIZATION=Organization
#valid for 10 years
SELFSIGNEDCERT_CERTIFICATE_VALID_DAYS=3650
SELFSIGNEDCERT_CERTIFICATE_EMAIL_ADDRESS_NAME=mr.smith
#CA cert organization
SELFSIGNED_CACERT_ORGANIZATION="Sami Salkosuo"


__cert_dir="$(pwd)/certs"
__tmp_cert_dir=$__cert_dir/tmp
mkdir -p $__tmp_cert_dir

function usage
{
  echo "Self-signed certificate helper."
  echo ""
  echo "Usage: $0 <command> <command-args>"
  echo ""
  echo "Commands:"
  echo "  create-ca-cert <domain>                                          - Create CA certificate for given domain."
  echo "  create-cert-using-ca <domain> <basename> [alt_name alt_name ...] - Create self-signed certificate using CA for basename and optional alt names."
  echo "  create-cert FQDN                                                 - Create self-signed certificate for given FQDN."
  echo "  add-ca-trusted <domain>                                          - Add CA certificate as trusted (RHEL based Linux only)."
  echo "  print-ca-cert <domain>                                           - Print CA certificate for given domain."
  echo "  print-cert <domain> <basename>                                   - Print certificate for given domain and basename."
  echo "  cat-certs <domain> <basename>                                    - Cat certificate and CA certificate for given domain and basename."
  exit 1
}

function error
{
  echo "ERROR: $1"
  exit 2
}

set -e

function catCerts
{
  shift
  if [[ "$1" == "" ]]; then
    error "Domain not specified."
  fi
  if [[ "$2" == "" ]]; then
    error "Base name not specified."
  fi
  local __domain=$1
  local __base_name=$2
  local __common_name=${__base_name}.${__domain}
  local __ca_file_name=$__cert_dir/CA_${__domain}.crt
  local __cert_file_name=$__cert_dir/${__common_name}.crt
  
  cat $__cert_file_name $__ca_file_name
}

function printCACert
{
  if [[ "$2" == "" ]]; then
    error "Domain not specified."
  fi
  local __domain=$2
  local __ca_file_name=$__cert_dir/CA_${__domain}
  #openssl x509 -in ${__ca_file_name}.crt -text -noout
  openssl x509 -in ${__ca_file_name}.crt -text 
}

function printCert
{
  shift
  if [[ "$1" == "" ]]; then
    error "Domain not specified."
  fi
  if [[ "$2" == "" ]]; then
    error "Base name not specified."
  fi

  local __domain=$1
  local __base_name=$2
  local __common_name=${__base_name}.${__domain}
  #openssl x509 -in $__cert_dir/${__common_name}.crt -text -noout
  openssl x509 -in $__cert_dir/${__common_name}.crt -text
}

function createCACert
{
   if [[ "$2" == "" ]]; then
     error "Domain not specified."
   fi
    echo "creating CA-cert..."
    local __domain=$2
    local __country_name=$SELFSIGNEDCERT_COUNTRY
    local __org_name=$SELFSIGNED_CACERT_ORGANIZATION
    local __ca_cert_config_file=$__tmp_cert_dir/ca_cert_config_${__domain}.txt
    if [  -f "${__ca_cert_config_file}" ]; then
        echo "CA certificate seems to be already created..."
        error "Check ${__ca_cert_config_file}..."
    fi

    mkdir -p $__cert_dir
    cat > ${__ca_cert_config_file} << EOF
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

    local __ca_file_name=$__cert_dir/CA_${__domain}
    openssl req -x509 -config ${__ca_cert_config_file} -extensions server_exts -nodes -days $SELFSIGNEDCERT_CERTIFICATE_VALID_DAYS -newkey rsa:4096 -keyout ${__ca_file_name}.key -out ${__ca_file_name}.crt


    echo ""
    echo "CA Certificate created."
    echo "view certificate using command:"
    echo "  openssl x509 -in ${__ca_file_name}.crt -text -noout"

    echo "creating CA-cert...done."

}

function addCACertAsTrusted
{
  if [[ "$2" == "" ]]; then
    error "Domain not specified."
  fi
  local __domain=$2
  local __ca_file_name=$__cert_dir/CA_${__domain}.crt
  if [ ! -f "${__ca_file_name}" ]; then
    error "CA certificate ${__ca_file_name} does not exist."
  fi

  if [ ! -d "/etc/pki/ca-trust/source/anchors/" ]; then
    error "Directory /etc/pki/ca-trust/source/anchors/ does not exist. Can not add CA cert as trusted. Check Linux distro docs."
  fi

  echo "Adding CA cert as trusted..."
  cp ${__ca_file_name} /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract

}

function createSelfSignedCertUsingCA
{
  shift
  if [[ "$1" == "" ]]; then
    error "Domain not specified."
  fi
  if [[ "$2" == "" ]]; then
    error "Base name not specified."
  fi

  set -e

  echo "Creating self-signed certificate using CA..."

  local __domain=$1
  local __ca=$__domain
  local __base_name=$2
  shift
  shift
  local __alt_names_array=($*)

  local __validity_days=$SELFSIGNEDCERT_CERTIFICATE_VALID_DAYS
  local __common_name=${__base_name}.${__domain}
  local __ca_file_name=$__cert_dir/CA_${__ca}.crt
  local __csr_file=$__tmp_cert_dir/${__common_name}_csr.txt

  if [  -f "$__csr_file" ]; then
      echo "Self-signed certificate seems to be already created..."
      error "check $__cert_dir and/or delete $__csr_file"
  fi

  cat > ${__csr_file} << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = req_ext
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=${SELFSIGNEDCERT_COUNTRY}
O=${SELFSIGNEDCERT_ORGANIZATION}
emailAddress=${SELFSIGNEDCERT_CERTIFICATE_EMAIL_ADDRESS_NAME}@${__domain}
CN = ${__common_name}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${__base_name}
DNS.2 = ${__common_name}
DNS.3 = ${__common_name}.local
EOF

  local position=3
  for ((i = 0; i < ${#__alt_names_array[@]}; ++i)); do
      # bash arrays are 0-indexed
      position=$(( $position + 1 ))
      name=${__alt_names_array[$i]}
      echo "DNS.$position  = $name" >> ${__csr_file}
      position=$(( $position + 1 ))
      echo "DNS.$position  = $name.${__domain}" >> ${__csr_file}
      position=$(( $position + 1 ))
      echo "DNS.$position  = $name.${__domain}.local" >> ${__csr_file}
  done

  #create registry certificate key:
  openssl genrsa -out $__cert_dir/${__common_name}.key 4096

  #create CSR:  
  openssl req -new -sha256 -key $__cert_dir/${__common_name}.key -out $__tmp_cert_dir/${__common_name}.csr -config ${__csr_file}

  local __srl_file=$__tmp_cert_dir/CA_${__domain}.srl
  local __serial_option="-CAcreateserial"
  if [ -f "$__srl_file" ]; then
    #use existing serial number file 
    __serial_option="-CAserial $__srl_file"
  fi
  #sign CSR usign CA cert
  openssl x509 -req \
            -extfile ${__csr_file} \
            -extensions req_ext \
            -in $__tmp_cert_dir/${__common_name}.csr \
            -CA $__cert_dir/CA_${__ca}.crt \
            -CAkey $__cert_dir/CA_${__ca}.key  \
            $__serial_option \
            -out $__cert_dir/${__common_name}.crt \
            -days ${__validity_days} \
            -sha256 

  #move all *srl file to temp dir and ignore any errors
  mv $__cert_dir/*.srl $__tmp_cert_dir/ &> /dev/null || true

  echo "Creating self-signed certificate using CA...done."
#  echo "Self-signed certificate created"
  echo "view it using command:"
  echo "  openssl x509 -in $__cert_dir/${__common_name}.crt -text -noout"

}

function createCertForName
{
  
  local subject=$1
  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout $__cert_dir/${subject}.key -out ${__cert_dir}/${subject}.crt -subj "/CN=${subject}" \
  -addext "subjectAltName=DNS:${subject}"
  #use -addext "server.example.com,DNS:server,IP:127.0.01"
  #in order to use more alt names 
}

case "$1" in
    create-ca-cert)
        createCACert $*
        ;;
    create-cert-using-ca)
      createSelfSignedCertUsingCA $*
      ;;
    print-ca-cert)
      printCACert $*
      ;;
    print-cert)
      printCert $*
      ;;
    create-cert)
      createCertForName $2
      ;;
    cat-certs)
      catCerts $*
      ;;
    add-ca-trusted)
      addCACertAsTrusted $*
      ;;
    *)
      usage
      ;;
esac
