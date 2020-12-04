

if [[ "${__operation}" == "create-external-registry" ]]; then
  echo "creating external registry..."
  cd ${__config_dir}/external-registry  
  sh create-external_registry.sh ${__current_dir}/install/certificates/domain.crt ${__current_dir}/install/certificates/domain.key
  cd ${__current_dir}
  echo "creating external registry...done."
fi
