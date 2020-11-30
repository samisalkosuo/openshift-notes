#omg.sh CA and other certs


if [[ "${__operation}" == "create-registry-cert" ]]; then
  echo "creating registry cert..."
  cd ${__script_dir}/certificates
  sh create_registry_cert.sh
  echo "creating registry cert...done."
fi

if [[ "${__operation}" == "create-ca-cert" ]]; then
  echo "creating CA cert..."
  cd ${__script_dir}/certificates
  sh create_ca_cert.sh
  echo "creating CA cert...done."
fi
