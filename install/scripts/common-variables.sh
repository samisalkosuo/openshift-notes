
#common variables used in function scripts
__omg_runtime_dir=$(pwd)/run-omg
mkdir -p ${__omg_runtime_dir}
__omg_cert_dir=${__omg_runtime_dir}/certs

__omg_mirror_registry_host_name=mirror-registry
__omg_mirror_registry_user_name=admin
__omg_mirror_registry_user_password=passw0rd
__omg_mirror_registry_port=5000
__omg_mirror_registry_directory=/opt/mirror-registry
__omg_mirror_registry_systemd_service_name=mirror-registry

__omg_pull_secret_dir=${__omg_runtime_dir}/pull-secrets
