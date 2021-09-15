function mirrorOpenShiftImagesToFiles
{
    local imageDir=$__dist_dir/ocp-images
    mkdir -p $imageDir
    echo "Mirroring images to ${imageDir}..."

    oc adm -a ${OCP_PULL_SECRET_FILE} release mirror --from=quay.io/${__ocp_product_repo}/${__ocp_release_name}:${__ocp_release} --to-dir=${imageDir} 2>&1 | tee $__dist_dir/mirror-output.txt

}

function mirrorOpenShiftImagesToMirrorRegistry
{
    local __registry=${__mirror_registry_base_name}.${OCP_DOMAIN}:${__mirror_registry_port}
    local __ocp_repo=$__ocp_local_repository
    local imageDir=$__dist_dir/ocp-images
    echo "Mirroring images to ${__registry}/${__ocp_repo}..."
    local mirrorCmd=$(cat mirror-output.txt |grep "oc image mirror" |sed "s|REGISTRY/REPOSITORY|${__registry}/${__ocp_repo}|g")

    echo "Creating pull secret..."
    podman login ${__registry} -u $__mirror_registry_user -p $__mirror_registry_password
    cat ${XDG_RUNTIME_DIR}/containers/auth.json | jq -c . > ${OCP_PULL_SECRET_FILE}
    #command
    #echo oc image mirror --max-registry=1 --from-dir=$imageDir 'file://openshift/release:${OCP_VERSION}*' ${__registry}/${__ocp_repo}
    mirrorCmd=$(echo $mirrorCmd | sed "s@mirror @mirror -a ${OCP_PULL_SECRET_FILE} --max-registry=1 @g")

    echo $mirrorCmd | sh
    
}