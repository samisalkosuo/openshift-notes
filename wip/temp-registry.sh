#/bin/bash

REGISTRY_NAME=temp-registry
REGISTRY_DIR=$(pwd)/temp-registry
REGISTRY_USER_NAME=admin
REGISTRY_USER_PASSWORD=passw0rd
REGISTRY_PORT=6000
REGISTRY_IMAGE=docker.io/library/registry:2

function usage
{
  echo "Temp registry helper."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo "  create     - Create local temporary registry."
  echo "  start      - Start local temporary registry."
  echo "  stop       - Stop local temporary registry."
  exit 1
}

function error
{
  echo "ERROR: $1"
  exit 2
}

set -e 

#temp registry main use case is to push custom operatorhub index image for mirroring images
function createTemporaryRegistry
{
    echo "creating temporary registry..."
    local __registry_crt_file=/tmp/temp-registry.crt
    local __registry_key_file=/tmp/temp-registry.key

    #create temp certificate
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout ${__registry_key_file} -out ${__registry_crt_file} -subj "/CN=temp-registry" \
  -addext "subjectAltName=DNS:temp-registry,DNS:localhost,IP:127.0.0.1"
    
    #create registry directories
    mkdir -p ${REGISTRY_DIR}/{auth,certs,data}

    #create registry user to registry dir
    htpasswd -bBc ${REGISTRY_DIR}/auth/htpasswd ${REGISTRY_USER_NAME} ${REGISTRY_USER_PASSWORD}

    #certificate and key file are copied to registry certs-dire as domain.crt and domain.key
    cp ${__registry_crt_file} ${REGISTRY_DIR}/certs/domain.crt
    cp ${__registry_key_file} ${REGISTRY_DIR}/certs/domain.key

    /usr/bin/podman pull $REGISTRY_IMAGE

    echo "adding temp registry certificate as trusted"
    cp ${__registry_crt_file} /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract

    echo "creating temporary registry...done."

}

function startRegistry
{
    echo "starting temporary registry..."
    /usr/bin/podman run \
                    -d --rm \
                    --name $REGISTRY_NAME \
                    -p ${REGISTRY_PORT}:5000 \
                    -v ${REGISTRY_DIR}/data:/var/lib/registry:z \
                    -v ${REGISTRY_DIR}/auth:/auth:z \
                    -v ${REGISTRY_DIR}/certs:/certs:z \
                    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
                    -e REGISTRY_AUTH=htpasswd \
                    -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
                    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
                    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
                    -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
                    ${REGISTRY_IMAGE}

    echo "log in to temporary registry..."
    /usr/bin/podman login -u ${REGISTRY_USER_NAME} -p ${REGISTRY_USER_PASSWORD} localhost:${REGISTRY_PORT}

    echo "test registry using command:"
    echo "  curl -u ${REGISTRY_USER_NAME}:${REGISTRY_USER_PASSWORD} https://localhost:${REGISTRY_PORT}/v2/_catalog"

}

function stopRegistry
{
    echo "stopping temporary registry..."
    /usr/bin/podman stop $REGISTRY_NAME

}


case "$1" in
    create)
        createTemporaryRegistry
        ;;
    start)
        startRegistry
        ;;
    stop)
        stopRegistry
        ;;
    *)
        usage
        ;;
  esac
