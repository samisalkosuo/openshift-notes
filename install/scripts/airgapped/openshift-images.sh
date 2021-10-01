function mirrorOpenShiftImagesToFiles
{
    if [[ "$1" == "" ]]; then
      error "Download directory not available."
    fi
    local imageDir=$1
    if [ -d "${imageDir}" ]
    then
        echo "Download directory ${imageDir} already exists. Will not download again."
        echo "'rm -rf ${imageDir}' if you want to download images again."
    else
        #does not exist, download
        mkdir -p $imageDir
        echo "Mirroring images to ${imageDir}..."

        oc adm -a ${OCP_PULL_SECRET_FILE} release mirror --from=quay.io/${__ocp_product_repo}/${__ocp_release_name}:${__ocp_release} --to-dir=${imageDir} 2>&1 | tee $__dist_dir/mirror-output.txt
    fi
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

function mirrorOpenShiftUpdateToMirrorRegistry
{
    local tarFile=$1
    local tarFilename=$(basename $tarFile)
    if [ ! -f "$tarFile" ]; then
        if [ ! -f "$tarFilename" ]; then
            error "$tarFile does not exist."
        fi
    fi
    echo "checking oc..."
    oc whoami
    echo "checking oc...ok."
    echo "Mirroring update images from ${tarFile}..."
    if [  -f "$tarFile" ]; then
        mv $tarFile .
    fi
    local dirName=$(echo $tarFilename |sed "s/\.tar//g")
    local ocpVersion=$(echo $dirName |sed "s/dist-//g")
    if [ -d "$dirName" ]; then
        echo "$dirName directory exists."
    else
        echo "Extracting ${tarFilename}..."
        tar -xf $tarFilename
    fi

    local __registry=${__mirror_registry_base_name}.${OCP_DOMAIN}:${__mirror_registry_port}
    local __local_registry=${__registry}/$__ocp_local_repository

    #mirror images to registry
    oc image mirror  -a ${OCP_PULL_SECRET_FILE} --from-dir=${dirName} "file://openshift/release:${ocpVersion}*" ${__local_registry}

    echo "Applying image signature file..." 
    #get latest yaml file in cnfig dire
    local __signature_file=$(ls -t ${dirName}/config/signature*yaml | head -n1)
    oc apply -f $__signature_file
    
    local __sha_sum=$(cat $__signature_file |jq -j .metadata.name)
    local __sha_sum=$(echo $__sha_sum | sed "s/-/:/g")
    
    echo "Mirroring update images from ${tarFile}...done."
    echo ""
    echo "use the following command to upgrade OpenShift to version $OCP_VERSION:"
    echo oc adm upgrade --allow-explicit-upgrade --to-image ${__local_registry}@${__sha_sum}

}