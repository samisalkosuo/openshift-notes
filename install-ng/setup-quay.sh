#setup quay registry

if [[ "$OMG_OCP_MIRROR_REGISTRY_HOST_NAME" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi



#assumes that registry images are present in a tar- file

REGISTRY_IMAGES_DIR=registry-images
PKG_NAME=$REGISTRY_IMAGES_DIR.tar

#quay directory
export QUAY=/opt/quay

POSTGRES_USER=admin
POSTGRES_PASSWORD=passw0rd
REDIS_PASSWORD=passw0rd

REGISTRY_FQDN=$OMG_OCP_MIRROR_REGISTRY_HOST_NAME.$OMG_OCP_DOMAIN
REGISTRY_TITLE="Project Quay"
REGISTRY_TITLE_SHORT="Project Quay"
REGISTRY_HTTP_PORT=80
REGISTRY_HTTPS_PORT=$OMG_OCP_MIRROR_REGISTRY_PORT

POSTGRES_SERVICE_NAME=quay-postgres
REDIS_SERVICE_NAME=quay-redis

QUAY_SUPERUSER=admin

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
    echo "Add CA as trusted"
    echo "sh self-signed-cert.sh add-ca-trusted $OMG_OCP_DOMAIN"    
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
    echo "loading images..."
    tar -xf $PKG_NAME
    cd $REGISTRY_IMAGES_DIR
    ls -1 | awk '{print "podman load -i " $1}' | sh
    cd ..
    echo "loading images...done."
}

function setupQuay
{
    mkdir -p $QUAY/storage
    setfacl -m u:1001:-wx $QUAY/storage
    mkdir -p $QUAY/config/extra_ca_certs

    #copy certs
    cp $CERT_DIR/CA_$OMG_OCP_DOMAIN.crt $QUAY/config/extra_ca_certs/ca.cert
    cp $CERT_DIR/$REGISTRY_FQDN.crt $QUAY/config/ssl.cert
    cp $CERT_DIR/$REGISTRY_FQDN.key $QUAY/config/ssl.key
    chmod 444 $QUAY/config/ssl.*
    
    local __postgresIP=$(cat IP-${POSTGRES_SERVICE_NAME})
    local __redisIP=$(cat IP-${REDIS_SERVICE_NAME})

    cat > $QUAY/config/config.yaml << EOF
AUTHENTICATION_TYPE: Database
AVATAR_KIND: local
BUILDLOGS_REDIS:
    host: ${__redisIP}
    password: ${REDIS_PASSWORD}
    port: 6379
DATABASE_SECRET_KEY: d738026f-2dea-4f15-af9b-3a71483b8028
DB_CONNECTION_ARGS: {}
DB_URI: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${__postgresIP}/quay
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
    default:
        - LocalStorage
        - storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE:
    - default
FEATURE_ACI_CONVERSION: false
FEATURE_ACTION_LOG_ROTATION: false
FEATURE_ANONYMOUS_ACCESS: true
FEATURE_APP_REGISTRY: false
FEATURE_APP_SPECIFIC_TOKENS: true
FEATURE_BITBUCKET_BUILD: false
FEATURE_BLACKLISTED_EMAILS: false
FEATURE_BUILD_SUPPORT: false
FEATURE_CHANGE_TAG_EXPIRATION: true
FEATURE_DIRECT_LOGIN: true
FEATURE_EXTENDED_REPOSITORY_NAMES: true
FEATURE_FIPS: false
FEATURE_GITHUB_BUILD: false
FEATURE_GITHUB_LOGIN: false
FEATURE_GITLAB_BUILD: false
FEATURE_GOOGLE_LOGIN: false
FEATURE_INVITE_ONLY_USER_CREATION: false
FEATURE_MAILING: false
FEATURE_NONSUPERUSER_TEAM_SYNCING_SETUP: false
FEATURE_PARTIAL_USER_AUTOCOMPLETE: true
FEATURE_PROXY_STORAGE: false
FEATURE_REPO_MIRROR: false
FEATURE_REQUIRE_TEAM_INVITE: true
FEATURE_RESTRICTED_V1_PUSH: true
FEATURE_SECURITY_NOTIFICATIONS: false
FEATURE_SECURITY_SCANNER: false
FEATURE_STORAGE_REPLICATION: false
FEATURE_TEAM_SYNCING: false
FEATURE_USER_CREATION: true
FEATURE_USER_LAST_ACCESSED: true
FEATURE_USER_LOG_ACCESS: false
FEATURE_USER_METADATA: false
FEATURE_USER_RENAME: false
FEATURE_USERNAME_CONFIRMATION: true
FRESH_LOGIN_TIMEOUT: 10m
GITHUB_LOGIN_CONFIG: {}
GITHUB_TRIGGER_CONFIG: {}
GITLAB_TRIGGER_KIND: {}
LDAP_ALLOW_INSECURE_FALLBACK: false
LDAP_EMAIL_ATTR: mail
LDAP_UID_ATTR: uid
LDAP_URI: ldap://localhost
LOG_ARCHIVE_LOCATION: default
LOGS_MODEL: database
LOGS_MODEL_CONFIG: {}
MAIL_DEFAULT_SENDER: support@${OMG_OCP_DOMAIN}
MAIL_PORT: 587
MAIL_USE_AUTH: false
MAIL_USE_TLS: false
PREFERRED_URL_SCHEME: https
REGISTRY_TITLE: ${REGISTRY_TITLE}
REGISTRY_TITLE_SHORT: ${REGISTRY_TITLE_SHORT}
REPO_MIRROR_INTERVAL: 30
REPO_MIRROR_TLS_VERIFY: true
SEARCH_MAX_RESULT_PAGE_COUNT: 10
SEARCH_RESULTS_PER_PAGE: 10
SECRET_KEY: 8d9ce248-9415-4722-ae40-b57ee371ef90
SECURITY_SCANNER_INDEXING_INTERVAL: 30
SERVER_HOSTNAME: ${REGISTRY_FQDN}
SETUP_COMPLETE: true
SUPER_USERS:
    - ${QUAY_SUPERUSER}
TAG_EXPIRATION_OPTIONS:
    - 0s
    - 1d
    - 1w
    - 2w
    - 4w
TEAM_RESYNC_STALE_TIME: 30m
TESTING: false
USE_CDN: false
USER_EVENTS_REDIS:
    host: ${__redisIP}
    password: ${REDIS_PASSWORD}
    port: 6379
USER_RECOVERY_TOKEN_LIFETIME: 30m
USERFILES_LOCATION: default
EOF

    local __service_name=quay-registry

    #create service file
    local __service_file=/etc/systemd/system/${__service_name}.service
    cat > ${__service_file} << EOF
[Unit]
Description=${__service_name} Podman Container

[Service]
ExecStartPre=-/usr/bin/podman rm -i -f ${__service_name}
ExecStart=/usr/bin/podman run --rm -p ${REGISTRY_HTTP_PORT}:8080 -p ${REGISTRY_HTTPS_PORT}:8443 --name=${__service_name} --privileged=true -v $QUAY/config:/conf/stack:Z -v $QUAY/storage:/datastorage:Z quay.io/projectquay/quay:3.7.6
Restart=always
KillMode=control-group
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    echo "starting ${__service_name} service..."
    systemctl daemon-reload
    systemctl restart ${__service_name} && systemctl enable ${__service_name}

    # echo "Open registry ports..."
    # firewall-cmd --add-port=$REGISTRY_HTTP_PORT/tcp --add-port=$REGISTRY_HTTPS_PORT/tcp
    # #persist firewall settings
    # firewall-cmd --runtime-to-permanent

    #sleeping 5 seconds so that postgres starts..
    sleep 5

    echo "Go to Quay and create superuser with name '${QUAY_SUPERUSER}'"
 
}

function setupPostgres
{
    mkdir -p $QUAY/postgres
    setfacl -m u:26:-wx $QUAY/postgres

    #create service file
    local __service_file=/etc/systemd/system/${POSTGRES_SERVICE_NAME}.service
    cat > ${__service_file} << EOF
[Unit]
Description=${POSTGRES_SERVICE_NAME} Podman Container

[Service]
ExecStartPre=-/usr/bin/podman rm -i -f ${POSTGRES_SERVICE_NAME}
ExecStart=/usr/bin/podman run --rm --name ${POSTGRES_SERVICE_NAME} -p 5432:5432 -v $QUAY/postgres:/var/lib/postgresql/data:Z  -e POSTGRES_USER=${POSTGRES_USER} -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} -e POSTGRES_DB=quay docker.io/library/postgres:10.12
Restart=always
KillMode=control-group
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    echo "starting ${POSTGRES_SERVICE_NAME} service..."
    systemctl daemon-reload
    systemctl restart ${POSTGRES_SERVICE_NAME} && systemctl enable ${POSTGRES_SERVICE_NAME}

    #sleeping 5 seconds so that postgres starts..
    sleep 5

    #install pg_trgm module
    podman exec -it ${POSTGRES_SERVICE_NAME} /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U ${POSTGRES_USER}'

    local __ipaddress=$(hostname --all-ip-addresses | awk '{print $1}')
    #local __ipaddress=$(podman inspect -f "{{.NetworkSettings.IPAddress}}" ${POSTGRES_SERVICE_NAME})
    echo $__ipaddress > IP-${POSTGRES_SERVICE_NAME}

}

function setupRedis
{
    #create service file
    local __service_file=/etc/systemd/system/${REDIS_SERVICE_NAME}.service
    cat > ${__service_file} << EOF
[Unit]
Description=${REDIS_SERVICE_NAME} Podman Container

[Service]
ExecStartPre=-/usr/bin/podman rm -i -f ${REDIS_SERVICE_NAME}
ExecStart=/usr/bin/podman run --rm --name ${REDIS_SERVICE_NAME} -p 6379:6379 redis:5.0.14 --requirepass ${REDIS_PASSWORD}
Restart=always
KillMode=control-group
Type=simple

[Install]
WantedBy=multi-user.target
EOF

    echo "starting ${REDIS_SERVICE_NAME} service..."
    systemctl daemon-reload
    systemctl restart ${REDIS_SERVICE_NAME} && systemctl enable ${REDIS_SERVICE_NAME}

    #sleeping 5 seconds so that redis starts..
    sleep 5

    #get local IP address
    local __ipaddress=$(hostname --all-ip-addresses | awk '{print $1}')
    #local __ipaddress=$(podman inspect -f "{{.NetworkSettings.IPAddress}}" ${REDIS_SERVICE_NAME})
    echo $__ipaddress > IP-${REDIS_SERVICE_NAME}

}

loadImages
setupPostgres
setupRedis

setupQuay
