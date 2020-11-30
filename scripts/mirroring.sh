#omg.sh mirroring commands

if [[ "${__operation}" == "create-mirror-image-registry" ]]; then
  echo "creating mirror image registry..."
  cd ${__script_dir}/registry
  echo "pulling registry image..."
  podman pull docker.io/library/registry:2  
  sh create_registry.sh ../certificates/domain.crt ../certificates/domain.key
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
  echo "downloading openshift-install.."
  sh create_install_files.sh ../certificates/CA_$OCP_DOMAIN.crt
  echo "doing mirroring...done."

fi

