
#common variables used in function scripts
#can be changed if so desired

#runtime directory used when executing omg scripts
__omg_runtime_dir=$(pwd)/runtime-omg
mkdir -p ${__omg_runtime_dir}

#OpenShift install dir, used while installing OpenShift
#holds kubeconfig authentication file in auth-subdirectory
__openshift_install_dir=~/ocp-install

__openshift_ipi_install_dir=~/ocp-ipi-install

__dist_dir=~/ocp-dist

#SSH key file
__ssh_type=rsa
__ssh_key_file=~/.ssh/id_rsa

#variable for mirroring for airgapped environment
#do not change, unless explicitly instructed 
__ocp_release="${OCP_VERSION}-x86_64"
__ocp_local_repository='ocp/openshift4'
__ocp_product_repo='openshift-release-dev'
__ocp_release_name="ocp-release"

#container images used or potentially used in airgapped bastion
__container_images="docker.io/library/registry:2 \
                    docker.io/osixia/openldap:1.5.0 \
                    python:3.9.7-alpine3.14 \
                    k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"

__container_image_dir=$__dist_dir/images_containers

#potentially useful git repositories to be used in airgapped bastion
__git_repositories="https://github.com/samisalkosuo/openldap-docker.git \
                    https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner \
                    "
__gitrepo_dir=$__dist_dir/git_repos

#certificate dir for generated certificates
__certificates_dir=~/ocp-certificates

#mirror registry config
__mirror_registry_base_name=mirror-registry
__mirror_registry_alt_names="registry external-registry localhost registry1 registry2"
__mirror_registry_directory=/opt/mirror-registry
__mirror_registry_port=5000
__mirror_registry_user=admin
__mirror_registry_password=passw0rd

#URLs for RHCOS files and ignition files
#used in PXE variables, RHCOS files
__rhcos_kernel_url=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/rhcos/rhcos-${OCP_RHCOS_VERSION}-x86_64-live-kernel-x86_64
__rhcos_initramfs_url=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/rhcos/rhcos-${OCP_RHCOS_VERSION}-x86_64-live-initramfs.x86_64.img
__rhcos_rootfs_url=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/rhcos/rhcos-${OCP_RHCOS_VERSION}-x86_64-live-rootfs.x86_64.img

#Ignition files
__ignition_url_bootstrap=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/ignition/bootstrap.ign
__ignition_url_master=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/ignition/master.ign
__ignition_url_worker=http://${OCP_APACHE_HOST}:${OCP_APACHE_PORT}/ignition/worker.ign
