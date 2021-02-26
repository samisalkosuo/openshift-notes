
function createCACert
{
    echo "creating CA-cert..."
    local __domain=$1
    local __country_name=FI
    local __org_name=ORG
    if [  -f "$__omg_cert_dir/ca_cert_config.txt" ]; then
        echo "CA certificate seems to be created..."
        error "Check $__omg_cert_dir..."
    fi

    mkdir -p $__omg_cert_dir
    cat > $__omg_cert_dir/ca_cert_config.txt << EOF
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

    local __ca_file_name=$__omg_cert_dir/CA_${__domain}
    openssl req -x509 -config $__omg_cert_dir/ca_cert_config.txt -extensions server_exts -nodes -days 3650 -newkey rsa:4096 -keyout ${__ca_file_name}.key -out ${__ca_file_name}.crt

    echo "Adding CA cert as trusted..."
    cp ${__ca_file_name}.crt /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract

    echo ""
    echo "CA Certificate created."
    echo "view certificate using command:"
    echo "  openssl x509 -in ${__ca_file_name}.crt -text -noout"

    echo "creating CA-cert...done."

}


function createRegistryCert
{
    echo "creating registry certificate..."
    local __domain=$1
    local __validity_days=3650
    local __base_name=registry
    local __common_name=${__base_name}.${__domain}
    local __alt_names=(mirror-registry ocp-registry operator-registry external-registry localhost registry1 registry2 registry3 registry4 registry5)

    set -e
    __csr_file=$__omg_cert_dir/${__base_name}_csr.txt

    if [  -f "$__csr_file" ]; then
        echo "registry certificate seems to be created..."
        error "check $__omg_cert_dir..."
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
    openssl genrsa -out $__omg_cert_dir/${__base_name}.key 4096

    #create CSR:  
    openssl req -new -sha256 -key $__omg_cert_dir/${__base_name}.key -out $__omg_cert_dir/${__base_name}.csr -config ${__csr_file}

    #sign CSR usign CA cert
    openssl x509 -req \
             -extfile ${__csr_file} \
             -extensions req_ext \
             -in $__omg_cert_dir/${__base_name}.csr \
             -CA $__omg_cert_dir/CA_${__domain}.crt \
             -CAkey $__omg_cert_dir/CA_${__domain}.key  \
             -CAcreateserial \
             -out $__omg_cert_dir/${__base_name}.crt \
             -days ${__validity_days} \
             -sha256 

    #combine CA and registry certs
    cat $__omg_cert_dir/${__base_name}.crt $__omg_cert_dir/CA_${__domain}.crt > $__omg_cert_dir/domain.crt
    cp $__omg_cert_dir/${__base_name}.key $__omg_cert_dir/domain.key

    echo "registry certificate created"
    echo "view it using command:"
    echo "  openssl x509 -in $__omg_cert_dir/${__base_name}.crt -text -noout"
    echo ""
    echo "use following files as registry certificate:"
    echo "  $__omg_cert_dir/domain.crt"
    echo "  $__omg_cert_dir/domain.key" 

    echo "creating registry certificate...done."
}
