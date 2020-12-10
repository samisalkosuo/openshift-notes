
#omg.sh operations

if [[ "${__operation}" == "get-kubeterminal" ]]; then
  echo "downloading KubeTerminal..."
  downloadKubeTerminal
  echo "downloading KubeTerminal...done."

fi

if [[ "${__operation}" == "create-haproxy-dist-package" ]]; then
  check_role bastion_online
  __dist_dir=dist
  __repodir=${__dist_dir}/local_repository
  mkdir -p $__repodir

  echo "creating haproxy distribution files..."

  echo "downloading podman..."
  dnf --enablerepo=epel-testing --alldeps download --downloaddir $__repodir --resolve  podman

  echo "creating repository..."
  cd $__repodir
  createrepo_c .
  repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
  createrepo_mod .
  cd $__current_dir

  echo "saving haproxy container images..."
  podman images |grep  "haproxy" |awk -v dir="${__dist_dir}" '{print "podman save -o " dir "/img_"  $3".tar " $1 ":" $2}' |sh

  echo "copying haproxy service file..."
  function copySvcFile
  {
    cp /etc/systemd/system/${1}.service ${__dist_dir}/
  }
  copySvcFile ${OCP_SERVICE_NAME_HAPROXY_SERVER}
  
  echo "packaging scripts..."  
  tar -czf ${__dist_dir}/scripts.tgz ${__script_dir}/haproxy/
  echo "creating tar..."
  tar -cf ${__dist_dir}.tar ${__dist_dir}/
  tar -rf ${__dist_dir}.tar *sh scripts/*

  echo "creating haproxy distribution files...done."
  echo "copy/move following file to haproxy server:"
  echo "  ${__dist_dir}.tar"

fi

if [[ "${__operation}" == "create-dist-packages" ]]; then
  check_role jump

  __dist_dir=dist
  __repodir=${__dist_dir}/local_repository
  mkdir -p $__repodir

  echo "creating distribution files..."

  echo "downloading packages..."
  dnf --enablerepo=epel-testing --alldeps download --downloaddir $__repodir --resolve  $__packages

  echo "creating repository..."
  cd $__repodir
  createrepo_c .
  repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
  createrepo_mod .
  cd $__current_dir

  echo "saving container images..."
  podman images |grep -v "none\|TAG" |awk -v dir="${__dist_dir}" '{print "podman save -o " dir "/img_"  $3".tar " $1 ":" $2}' |sh

  echo "copying service files..."
  function copySvcFile
  {
    cp /etc/systemd/system/${1}.service ${__dist_dir}/
  }
  copySvcFile ${OCP_SERVICE_NAME_APACHE_RHCOS}
  copySvcFile ${OCP_SERVICE_NAME_MIRROR_REGISTRY}
  copySvcFile ${OCP_SERVICE_NAME_NTP_SERVER}
  copySvcFile ${OCP_SERVICE_NAME_DNS_SERVER}
  copySvcFile ${OCP_SERVICE_NAME_DHCPPXE_SERVER}
  copySvcFile ${OCP_SERVICE_NAME_HAPROXY_SERVER}

  echo "copying oc and kubectl..."
  cp /usr/local/bin/oc ${__dist_dir}/
  cp /usr/local/bin/kubectl ${__dist_dir}/

  echo "downloading kubeterminal..."
  cd ${__dist_dir}
  downloadKubeTerminal
  cd ${__current_dir}

  echo "packaging scripts..."  
  tar -czf ${__dist_dir}/scripts.tgz ${__script_dir}/boot-services/ ${__script_dir}/certificates/ ${__script_dir}/haproxy/ ${__script_dir}/ntp-server/ ${__script_dir}/mirroring/ ${__script_dir}/registry/
  echo "creating tar..."
  tar -cf ${__dist_dir}.tar ${__dist_dir}/
  #add omg-sh and other files to dist.tar file
  tar -rf ${__dist_dir}.tar *sh *adoc ${__script_dir}/*adoc scripts/* configure/* operation/*
  echo "packaging mirror registry..."
  tar -cf mirror-registry.tar $OCP_MIRROR_REGISTRY_DIRECTORY

  echo "creating distribution files...done."
  echo "copy/move following files to bastion server:"
  echo "  ${__dist_dir}.tar"
  echo "  mirror-registry.tar"
fi
