#omg.sh bastion related commands

function prepareAirgappedBastion
{
  echo "creating local repo..."
  __repodir=$(pwd)/dist/local_repository
  __repofile=/etc/yum.repos.d/local2.repo
  cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF
  prereq_install
  echo "extracting scripts..."
  tar -xf dist/scripts.tgz -C .
  echo "adding CA cert as trusted..."
  __ca_file_name=CA_${OCP_DOMAIN}
  cp ${__script_dir}/certificates/${__ca_file_name}.crt /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract
  echo "loading container images..."
  ls -1 dist/img_* |awk '{print "podman load -i " $1}' |sh
  echo "copying binaries to /usr/local/bin..."
  cp dist/kubectl dist/kubeterminal.bin dist/oc ${__script_dir}/mirroring/openshift-install /usr/local/bin/
  echo "copying systemctl services to /etc/systemd/system/..."
  cp dist/*.service /etc/systemd/system/
  echo "extracting mirror registry..."
  tar -xf mirror-registry.tar -C /

}


function prepareOnlineBastion
{
  echo "downloading oc-clients..."
  if [ ! -f "/usr/local/bin/oc" ]; then
    __oc_client_filename=openshift-client-linux.tar.gz
    curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/${__oc_client_filename} > ${__oc_client_filename}

    echo "Copying oc and kubectl to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__oc_client_filename}
  fi

  if [ ! -f "/usr/local/bin/openshift-install" ]; then
    __oc_client_filename=openshift-install-linux.tar.gz
    curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/${__oc_client_filename} > ${__oc_client_filename}

    echo "Copying openshift-install to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__oc_client_filename}
  fi

}

function createInstallConfigOnlineBastion
{
  cd ${__script_dir}/mirroring
  sh create_install_files.sh ../certificates/CA_$OCP_DOMAIN.crt
  cp install-config.yaml /home/${OCP_INSTALL_USER}/install/
  cd ${__current_dir}

}

if [[ "${__operation}" == "prepare-bastion" ]]; then
  check_role "bastion bastion_online"

  if [[ "$OCP_INSTALL_USER" == "" ]]; then
    usageEnv OCP_INSTALL_USER
  fi
  if [[ "$OCP_SERVICE_NAME_APACHE_IGNITION" == "" ]]; then
    usageEnv OCP_SERVICE_NAME_APACHE_IGNITION
  fi
  if [[ "$OCP_APACHE_IGNITION_PORT" == "" ]]; then
    usageEnv OCP_APACHE_IGNITION_PORT
  fi
  if [[ "$OCP_RHCOS_VERSION" == "" ]]; then
    usageEnv OCP_RHCOS_VERSION
  fi
  
  echo "preparing bastion..."  

  if [[ "$OCP_OMG_SERVER_ROLE" == "bastion" ]]; then
    prepareAirgappedBastion
  fi 

  if [[ "$OCP_OMG_SERVER_ROLE" == "bastion_online" ]]; then
    prepareOnlineBastion
  fi 

  echo "creating ocp-user..."
  useradd ${OCP_INSTALL_USER}
  echo "copying install-files to ocp-users install-directory..."
  mkdir -p /home/${OCP_INSTALL_USER}/install
  
  if [[ "$OCP_OMG_SERVER_ROLE" == "bastion" ]]; then
    cp ${__script_dir}/mirroring/install-config.yaml ${__script_dir}/mirroring/mirror-output.txt ${__script_dir}/mirroring/*json /home/${OCP_INSTALL_USER}/install/
  fi 
  if [[ "$OCP_OMG_SERVER_ROLE" == "bastion_online" ]]; then
    #create install-config.yaml file
    createInstallConfigOnlineBastion
  fi 

  chown -R ${OCP_INSTALL_USER}:${OCP_INSTALL_USER} /home/${OCP_INSTALL_USER}/install
  echo "creating ${OCP_INSTALL_USER}-user ssh key..."
  su - ${OCP_INSTALL_USER} -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
  echo "adding ${OCP_INSTALL_USER}-user ssh key to install-config.yaml..."
  su - ${OCP_INSTALL_USER} -c "echo -n \"sshKey: '\" >> install/install-config.yaml && cat ~/.ssh/id_rsa.pub | sed \"s/$/\'/g\" >> install/install-config.yaml"
  echo "backing up install-config.yaml..."
  su - ${OCP_INSTALL_USER} -c "cp install/install-config.yaml ~/install-config.yaml.backup"
  echo "creating manifest files..."
  su - ${OCP_INSTALL_USER} -c "cd install && openshift-install create manifests --dir=./"
  #when using airgapped user-provisioned infrastructure installation, master nodes are schedulable
  echo "configuring master nodes unschedulable..."
  su - ocp -c  "sed -i  \"s/mastersSchedulable: true/mastersSchedulable: false/g\" install/manifests/cluster-scheduler-02-config.yml"
  echo "creating ignition files..."
  su - ${OCP_INSTALL_USER} -c "cd install && openshift-install create ignition-configs --dir=./"
  echo "creating Apache server for ignition files..."
  __ign_dir=${__script_dir}/boot-services/ignition/
  cp /home/${OCP_INSTALL_USER}/install/*ign ${__ign_dir}
  chmod 644 ${__ign_dir}/*ign
  podman build -t ${OCP_SERVICE_NAME_APACHE_IGNITION} ${__ign_dir}
  __ign_service_file=${__ign_dir}/${OCP_SERVICE_NAME_APACHE_IGNITION}.service
  cp ${__ign_dir}/apache-ignition.service.template ${__ign_service_file}
  sed -i s/%SERVICE_NAME%/${OCP_SERVICE_NAME_APACHE_IGNITION}/g ${__ign_service_file}
  sed -i s/%PORT%/${OCP_APACHE_IGNITION_PORT}/g ${__ign_service_file}
  cp ${__ign_service_file} /etc/systemd/system/
  systemctl daemon-reload
  echo "starting Apache server for ignition files..."
  systemctl start ${OCP_SERVICE_NAME_APACHE_IGNITION}
  #sleep to allow server to start
  sleep 3
  echo "testing ignition file server..."
  curl http://${OCP_APACHE_IGNITION_HOST}:${OCP_APACHE_IGNITION_PORT}/
  echo "preparing bastion... done."

fi
