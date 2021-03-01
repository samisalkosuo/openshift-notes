#functions to update airgapped OpenShift

function downloadImagesAndCreatePackage
{
    echo "downloading and packaging updated OpenShift images..."
    echo "downloading ${OCP_VERSION} images..."
    local __images_dir=images-${OCP_VERSION}
    mkdir -p ${__images_dir}
    oc adm release mirror -a ${OCP_PULL_SECRET_FILE} --to-dir=${__images_dir} quay.io/${OCP_PRODUCT_REPO}/${OCP_RELEASE_NAME}:${OCP_RELEASE}

    local __image_tar_file=images-${OCP_VERSION}.tar
    echo "packaging images to ${__image_tar_file}..."
    tar -cf ${__image_tar_file} ${__images_dir}/
    echo "removing ${__images_dir}-directory..."
    rm -rf ${__images_dir}

    echo "downloading and packaging updated OpenShift images...done."
    echo ""
    echo "copy/move ${__image_tar_file} to bastion server."
}

function uploadUpdateImages
{
    echo "uploading updated OpenShift images to mirror registry..."
    echo "checking oc..."
    oc whoami
    echo "checking oc...ok."
    local __local_registry=$__omg_mirror_registry_host_name.$OCP_DOMAIN:$__omg_mirror_registry_port
    local __local_registry=${__local_registry}/${OCP_LOCAL_REPOSITORY}
    local __images_dir=images-${OCP_VERSION}
    if [ ! -d ${__images_dir} ]; then
      #images dir does not exists
      local __image_tar_file=images-${OCP_VERSION}.tar
      #find tar file and extract 
      local __image_tar_file_path=$(find / -name ${__image_tar_file})
      if [[ "$__image_tar_file_path" == "" ]]; then
          error "Image file $__image_tar_file not found.."
      fi
      mv $__image_tar_file_path .
      echo "extracting ${__image_tar_file}..."
      tar -xf $__image_tar_file
    fi

    echo "uploading images to ${__local_registry}..."
    oc image mirror  -a ${OCP_PULL_SECRET_FILE} --from-dir=${__images_dir} "file://openshift/release:${OCP_VERSION}*" ${__local_registry}
    
    echo "applying image signature file..." 
    #get latest yaml file in cnfig dire
    local __signature_file=$(ls -t ${__images_dir}/config/signature*yaml | head -n1)
    oc apply -f $__signature_file
    
    local __sha_sum=$(cat $__signature_file |jq -j .metadata.name)
    local __sha_sum=$(echo $__sha_sum | sed "s/-/:/g")
    
    echo "uploading updated OpenShift images to mirror registry...done."
    echo ""
    echo "use the following command to upgrade OpenShift to version $OCP_VERSION:"
    echo oc adm upgrade --allow-explicit-upgrade --to-image ${__local_registry}@${__sha_sum}

}