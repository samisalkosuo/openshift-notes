function createCACert
{
    echo "Creating CA-cert..."
    local __domain=$1
    local __country_name=FI
    local __org_name=ORG

    local __omg_cert_dir=$__certificates_dir

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

    echo "Creating CA-cert...done."

}


function createRegistryCert
{
    echo "creating registry certificate..."
    local __domain=$1
    local __validity_days=3650
    local __base_name=$__mirror_registry_base_name
    local __common_name=${__base_name}.${__domain}
    local __alt_names=($__mirror_registry_alt_names)
    local __omg_cert_dir=$__certificates_dir

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

    local position=3

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


function createRegistryContainerAndService
{
    echo "creating and starting mirror registry..."

    local __registry_host_name=${__mirror_registry_base_name}
    local __registry_service_name=${__mirror_registry_base_name}
    local __registry_dir=$__mirror_registry_directory
    local __registry_user_name=$__mirror_registry_user
    local __registry_user_password=$__mirror_registry_password
    local __registry_port=$__mirror_registry_port
    local __add_to_hosts_file=yes
    local __omg_cert_dir=$__certificates_dir
    local __registry_crt_file=${__omg_cert_dir}/domain.crt
    local __registry_key_file=${__omg_cert_dir}/domain.key

    #create registry directories
    mkdir -p ${__registry_dir}/{auth,certs,data}

    #create registry user to registry dir
    htpasswd -bBc ${__registry_dir}/auth/htpasswd ${__registry_user_name} ${__registry_user_password}

    #certificate and key file are copied to registry certs-dire as domain.crt and domain.key
    cp ${__registry_crt_file} ${__registry_dir}/certs/domain.crt
    cp ${__registry_key_file} ${__registry_dir}/certs/domain.key

    #create service file
    local __service_file=/etc/systemd/system/${__registry_service_name}.service
    cat > ${__service_file} << EOF
[Unit]
Description=${__registry_service_name} Podman Container

[Service]
ExecStartPre=-/usr/bin/podman rm -i -f ${__registry_service_name}
ExecStart=/usr/bin/podman run --rm --name ${__registry_service_name} -p ${__registry_port}:5000 -v ${__registry_dir}/data:/var/lib/registry:z -v ${__registry_dir}/auth:/auth:z -e REGISTRY_STORAGE_DELETE_ENABLED=true -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v ${__registry_dir}/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key docker.io/library/registry:2
Restart=always
KillMode=control-group
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    echo "starting ${__registry_service_name} service..."
    systemctl daemon-reload
    systemctl restart ${__registry_service_name}
    #sleeping 3 seconds so that registry starts..
    sleep 3

    echo "creating and starting mirror registry...done."

    if [[ "$__add_to_hosts_file" == "yes" ]]; then
        echo "adding \"127.0.01  ${__registry_host_name}.${OCP_DOMAIN}\" to /etc/hosts..."
        echo "127.0.0.1 ${__registry_host_name}.${OCP_DOMAIN}" >> /etc/hosts
    fi

    echo "use systemctl-commands commands to interact with the registry:"
    echo "  systemctl start|stop|status|enable|restart|disable ${__registry_service_name}"
    echo ""
    echo "test registry using command:"
    echo "  curl -u ${__registry_user_name}:${__registry_user_password} https://${__registry_host_name}.${OCP_DOMAIN}:${__registry_port}/v2/_catalog"

}

function createTemporaryRegistry
{
    #temp registry to push custom operatorhub index image for mirroring images
    #21.9.2021 mirroring does not work with local image, image must be in a registry
    echo "creating and starting temporary registry..."
    local __registry_host_name=temp-registry
    local __registry_dir=/opt/temp-registry
    local __registry_user_name=$__mirror_registry_user
    local __registry_user_password=$__mirror_registry_password
    local __registry_port=6000
    local __add_to_hosts_file=yes
    local __omg_cert_dir=$__certificates_dir
    local __registry_crt_file=/tmp/temp-registry.crt
    local __registry_key_file=/tmp/temp-registry.key

    #create temp certificate
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout ${__registry_key_file} -out ${__registry_crt_file} -subj "/CN=temp-registry" \
  -addext "subjectAltName=DNS:temp-registry,DNS:localhost,IP:127.0.0.1"
    
    #create registry directories
    mkdir -p ${__registry_dir}/{auth,certs,data}

    #create registry user to registry dir
    htpasswd -bBc ${__registry_dir}/auth/htpasswd ${__registry_user_name} ${__registry_user_password}

    #certificate and key file are copied to registry certs-dire as domain.crt and domain.key
    cp ${__registry_crt_file} ${__registry_dir}/certs/domain.crt
    cp ${__registry_key_file} ${__registry_dir}/certs/domain.key

    
    # if [[ "$__add_to_hosts_file" == "yes" ]]; then
    #     echo "adding \"127.0.01  ${__registry_host_name}\" to /etc/hosts..."
    #     echo "127.0.0.1 ${__registry_host_name}" >> /etc/hosts
    # fi

    echo "starting temporary registry..."
    /usr/bin/podman stop $__registry_host_name &> /dev/null || true
    /usr/bin/podman run -d --rm --name $__registry_host_name -p ${__registry_port}:5000 -v ${__registry_dir}/data:/var/lib/registry:z -v ${__registry_dir}/auth:/auth:z -e REGISTRY_STORAGE_DELETE_ENABLED=true -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v ${__registry_dir}/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key docker.io/library/registry:2

    echo "log in to temporary registry..."
    /usr/bin/podman login -u ${__registry_user_name} -p ${__registry_user_password} --tls-verify=false localhost:${__registry_port}

    echo "test registry using command:"
    echo "  curl -k -u ${__registry_user_name}:${__registry_user_password} https://localhost:${__registry_port}/v2/_catalog"

    echo "creating and starting temporary registry...done."

}