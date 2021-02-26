function createPullSecret
{
    echo "creating pull secrets..."

    mkdir -p ${__omg_pull_secret_dir}

    local __registry_host=$__omg_mirror_registry_host_name.$OCP_DOMAIN:$__omg_mirror_registry_port
    local __mirror_registry_secret=$(echo -n "${__omg_mirror_registry_user_name}:${__omg_mirror_registry_user_password}" | base64 -w0)
    local __email=mr.smith@$OCP_DOMAIN 
    local __pull_secret_bundle_file=${__omg_pull_secret_dir}/pull-secret-bundle.json
    local __pull_secret_mirror_file=${__omg_pull_secret_dir}/pull-secret-${__omg_mirror_registry_host_name}.json

    echo "creating pull-secret-bundle.json with mirror registry authentication..."
    cat $OCP_PULL_SECRET_FILE | jq  ".auths += {\"$__registry_host\": {\"auth\": \"REG_SECRET\",\"email\": \"$__email\"}}" | sed "s/REG_SECRET/$__mirror_registry_secret/" > $__pull_secret_bundle_file
    echo "creating pull-secret-${__omg_mirror_registry_host_name}.json just for mirror registry authentication..."
    echo '{"auths":{}}' | jq  ".auths += {\"$__registry_host\": {\"auth\": \"REG_SECRET\",\"email\": \"$__email\"}}" | sed "s/REG_SECRET/$__mirror_registry_secret/" > $__pull_secret_mirror_file 
    mv $__pull_secret_bundle_file tmp.json
    echo "adding localhost as mirror registry..."
    local __localhost_registry_host=localhost:$__omg_mirror_registry_port
    cat tmp.json | jq  ".auths += {\"$__localhost_registry_host\": {\"auth\": \"REG_SECRET\",\"email\": \"$__email\"}}" | sed "s/REG_SECRET/$__mirror_registry_secret/" > $__pull_secret_bundle_file
    rm -f tmp.json
    echo "creating pull secrets...done."
}

function mirrorOpenShiftImages
{
    echo "Mirroring images..."
    local __local_registry=$__omg_mirror_registry_host_name.$OCP_DOMAIN:$__omg_mirror_registry_port
    local __local_secret_json=${__omg_pull_secret_dir}/pull-secret-bundle.json
    local __mirror_output_file=${__omg_runtime_dir}/mirror-output.txt 

    oc adm -a ${__local_secret_json} release mirror --from=quay.io/${OCP_PRODUCT_REPO}/${OCP_RELEASE_NAME}:${OCP_RELEASE} --to=${__local_registry}/${OCP_LOCAL_REPOSITORY} --to-release-image=${__local_registry}/${OCP_LOCAL_REPOSITORY}:${OCP_RELEASE} 2>&1 | tee ${__mirror_output_file}

}