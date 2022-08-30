#setup  registry container

if [[ "$OMG_OCP_MIRROR_REGISTRY_HOST_NAME" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

#assumes that registry images are present in a tar- file

REGISTRY_IMAGES_DIR=registry-images
PKG_NAME=$REGISTRY_IMAGES_DIR.tar

#quay directory
export REGISTRY_DIR=/opt/registry

REGISTRY_FQDN=$OMG_OCP_MIRROR_REGISTRY_HOST_NAME.$OMG_OCP_DOMAIN
REGISTRY_HTTPS_PORT=$OMG_OCP_MIRROR_REGISTRY_PORT

REGISTRY_SERVICE_NAME=registry

REGISTRY_USER_NAME=admin
REGISTRY_USER_PASSWORD=passw0rd

CERT_DIR=certs/

if [[ ! -f "$PKG_NAME" ]]
then
    echo "$PKG_NAME does not exist."
    exit 1
fi

#check certificates
#CA and host cert must exist

function certHelp
{
    echo "generate CA certificate and registry certificate using commands:"
    echo "sh self-signed-cert.sh create-ca-cert $OMG_OCP_DOMAIN"
    echo "sh self-signed-cert.sh create-cert-using-ca $OMG_OCP_DOMAIN $OMG_OCP_MIRROR_REGISTRY_HOST_NAME"
    echo ""
    echo "CA certificate is also used when setting up OpenShift install."

}

if [[ ! -f "$CERT_DIR/CA_$OMG_OCP_DOMAIN.crt" ]]
then
    echo "CA certificate for domain $OMG_OCP_DOMAIN does not exist."
    certHelp
    exit 1
fi

if [[ ! -f "$CERT_DIR/$REGISTRY_FQDN.crt" ]]
then
    echo "Certificate for host $REGISTRY_FQDN does not exist."
    certHelp
    exit 1
fi


function loadImages
{
    tar -xf $PKG_NAME
    cd $REGISTRY_IMAGES_DIR
    ls -1 | awk '{print "podman load -i " $1}' | sh
    cd ..
}

function setupRegistry
{
    echo "creating and starting mirror registry..."

    local __registry_host_name=$REGISTRY_FQDN
    local __registry_service_name=$REGISTRY_SERVICE_NAME
    local __registry_dir=$REGISTRY_DIR
    local __registry_user_name=$REGISTRY_USER_NAME
    local __registry_user_password=$REGISTRY_USER_PASSWORD
    local __registry_port=$REGISTRY_HTTPS_PORT
    local __omg_cert_dir=$CERT_DIR
    local __registry_crt_file=${__omg_cert_dir}/domain.crt
    local __registry_key_file=${__omg_cert_dir}/domain.key

    #create registry directories
    mkdir -p ${__registry_dir}/{auth,certs,data}

    #create registry user to registry dir
    htpasswd -bBc ${__registry_dir}/auth/htpasswd ${__registry_user_name} ${__registry_user_password}

    #certificate and key file are copied to registry certs-dir as domain.crt and domain.key
    cp $CERT_DIR/$REGISTRY_FQDN.crt ${__registry_dir}/certs/domain.crt
    cp $CERT_DIR/$REGISTRY_FQDN.key ${__registry_dir}/certs/domain.key

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

    echo "use systemctl-commands commands to interact with the registry:"
    echo "  systemctl start|stop|status|enable|restart|disable ${__registry_service_name}"
    echo ""
    echo "test registry using command:"
    echo "  curl -u ${__registry_user_name}:${__registry_user_password} https://${__registry_host_name}.${OCP_DOMAIN}:${__registry_port}/v2/_catalog"

}


loadImages

setupRegistry
