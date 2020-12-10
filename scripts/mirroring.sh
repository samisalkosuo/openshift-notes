#omg.sh mirroring commands

if [[ "${__operation}" == "create-mirror-image-registry" ]]; then
  echo "creating mirror image registry..."
  cd ${__script_dir}/registry
  echo "pulling registry image..."
  podman pull docker.io/library/registry:2  
  sh create_registry.sh ../certificates/domain.crt ../certificates/domain.key
  cd ${__current_dir}
  echo "creating mirror image registry...done."
fi


if [[ "${__operation}" == "do-mirroring" ]]; then
  echo "doing mirroring..."

  if [ ! -f "pull-secret.json" ]; then
      echo "ERROR: pull-secret.json does not exist."
      echo "get it from Red Hat and copy it to this directory."
      exit 2
  fi
  cp pull-secret.json ${__script_dir}/mirroring
  cd ${__script_dir}/mirroring
  echo "downloading oc-client.."
  sh download_client.sh
  echo "creating pull secrets..."
  sh create_pull_secrets.sh
  echo "mirroring images.."
  sh mirror.sh
  echo "downloading openshift-install and creating install-config.yaml..."
  sh create_install_files.sh ../certificates/CA_$OCP_DOMAIN.crt
  cd ${__current_dir}
  echo "doing mirroring...done."

fi

if [[ "${__operation}" == "create-mirror-package" ]]; then
  #mirror OpenShift images to directory and package it
  #in order to upgrade OpenShift in airgapped environment
  echo "creating mirror image package..."
  if [ ! -f "pull-secret.json" ]; then
      echo "ERROR: pull-secret.json does not exist."
      echo "get it from Red Hat and copy it to this directory."
      exit 2
  fi
  echo "mirroring ${OCP_VERSION} images..."
  __mirror_images_dir=mirror-images
  __mirror_tar_file=mirror-images-${OCP_VERSION}.tar
  mkdir -p ${__mirror_images_dir}
  oc adm release mirror -a pull-secret.json --to-dir=${__mirror_images_dir} quay.io/${OCP_PRODUCT_REPO}/${OCP_RELEASE_NAME}:${OCP_RELEASE}
  echo "tarring mirror images to ${__mirror_tar_file}..."
  tar -cf ${__mirror_tar_file} ${__mirror_images_dir}/
  echo "removing ${__mirror_images_dir}-directory..."
  rm -rf ${__mirror_images_dir}
  echo "copy/move ${__mirror_tar_file} to bastion server."
  echo "creating mirror image package...done."
fi

if [[ "${__operation}" == "upload-mirror-package" ]]; then
  #mirror OpenShift images to directory and package it
  #in order to upgrade OpenShift in airgapped environment
  set -e
  __mirror_images_dir=mirror-images
  __mirror_tar_file=mirror-images-${OCP_VERSION}.tar
  if [ ! -f "${__mirror_tar_file}" ]; then
      echo "ERROR: ${__mirror_tar_file} does not exist."
      exit 3
  fi

  echo "uploading mirror image package..."
  __pull_secret_mirror_file=pull-secret-mirror.json
  echo "creating ${__pull_secret_mirror_file}..."
  __registry_name=$OCP_MIRROR_REGISTRY_HOST_NAME
  __registry_user_name=$OCP_MIRROR_REGISTRY_USER_NAME
  __registry_user_password=$OCP_MIRROR_REGISTRY_USER_PASSWORD
  __registry_port=$OCP_MIRROR_REGISTRY_PORT
  __registry_host=$__registry_name.$OCP_DOMAIN:$__registry_port
  __repository=$OCP_LOCAL_REPOSITORY
  __mirror_registry_secret=$(echo -n "${__registry_user_name}:${__registry_user_password}" | base64 -w0)
  __email=mr.smith@$OCP_DOMAIN
  echo '{"auths":{}}' | jq  ".auths += {\"$__registry_host\": {\"auth\": \"REG_SECRET\",\"email\": \"$__email\"}}" | sed "s/REG_SECRET/$__mirror_registry_secret/" > ${__pull_secret_mirror_file}
  
  echo "extracting ${__mirror_tar_file}..."
  tar -xf ${__mirror_tar_file}
  echo "uploading images to ${__registry_host}/${__repository}..."
  oc image mirror  -a ${__pull_secret_mirror_file} --from-dir=${__mirror_images_dir} "file://openshift/release:${OCP_VERSION}*" ${__registry_host}/${__repository}
  echo "applying image signature file..."
  #get latest yaml file in cnfig dire
  __signature_file=$(ls -t mirror-images/config/signature*yaml | head -n1)
  oc apply -f $__signature_file
  __sha_sum=$(cat $__signature_file |jq -j .metadata.name)
  __sha_sum=$(echo $__sha_sum | sed "s/-/:/g")
  echo "uploading mirror image package...done."
  echo ""
  echo "use the following command to upgrade OpenShift to version $OCP_VERSION:"
  echo oc adm upgrade --allow-explicit-upgrade --to-image ${__registry_host}/${__repository}@${__sha_sum}
fi
