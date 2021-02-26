
function createMirrorRegistry
{
    #registry variables
    local __add_to_hosts_file=yes
    createRegistryContainerAndService $__omg_mirror_registry_host_name $__omg_mirror_registry_systemd_service_name $__omg_mirror_registry_directory $__omg_mirror_registry_user_name $__omg_mirror_registry_user_password $__omg_mirror_registry_port $__add_to_hosts_file
}

function createRegistryContainerAndService
{
    echo "creating and starting mirror registry..."

    local __registry_host_name=$1
    local __registry_service_name=$2
    local __registry_dir=$3
    local __registry_user_name=$4
    local __registry_user_password=$5
    local __registry_port=$6
    local __add_to_hosts_file=$7
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
    __service_file=/etc/systemd/system/${__registry_service_name}.service
    echo "creating service file ${__service_file}..."
    cp templates/registry.service.template ${__service_file}

    #change values service file
    #note sed delimiter is ! instead of /
    sed -i s!%SERVICE_NAME%!${__registry_service_name}!g ${__service_file}
    sed -i s!%REGISTRY_DIR%!${__registry_dir}!g ${__service_file}
    sed -i s!%REGISTRY_PORT%!${__registry_port}!g ${__service_file}

    echo "service file created. File: ${__service_file}"

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
