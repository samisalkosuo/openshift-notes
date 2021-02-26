function setupOpenShiftInstall
{
  echo "Setting up OpenShift install..."

  local __network_cidr=$OCP_NODE_NETWORK_CIDR
  local __pull_secret_json=$(cat $OCP_PULL_SECRET_FILE | jq -c '')

  echo "creating install-config.yaml..."
  #create install-config.yaml
  local __install_cfg_file=install-config.yaml
  cp templates/install-config.yaml.template $__install_cfg_file

  #set variables
  sed -i s/%OCP_DOMAIN%/${OCP_DOMAIN}/g $__install_cfg_file
  sed -i s!%OCP_NODE_NETWORK_CIDR%!${__network_cidr}!g $__install_cfg_file
  sed -i s/%OCP_CLUSTER_NAME%/${OCP_CLUSTER_NAME}/g $__install_cfg_file
  sed -i s/%PULL_SECRET%/${__pull_secret_json}/g $__install_cfg_file

  #add CA certificate, if it exists
  local __ca_cert_file=$__omg_cert_dir/CA_${OCP_DOMAIN}.crt
  if [ -f $__ca_cert_file ]; then
    echo "additionalTrustBundle: |" >> $__install_cfg_file
    cat ${__ca_cert_file} | sed 's/^/\ \ \ \ \ /g' >> $__install_cfg_file
  fi

  #airgapped environment, add contents of mirror-output.txt, if it exists
  local __mirror_output_file=$__omg_runtime_dir/mirror-output.txt
  if [ -f $__mirror_output_file ]; then
    cat $__mirror_output_file | grep -A7 imageContentSources >> $__install_cfg_file
  fi

  #remove empty lines if there are any
  sed -i '/^[[:space:]]*$/d' $__install_cfg_file

  echo "creating ${OCP_INSTALL_USER}-user..."
  #try to add user, if user exists ignore it and continue
  useradd ${OCP_INSTALL_USER} || true

  echo "copying install-files to ocp-users install-directory..."
  mkdir -p /home/${OCP_INSTALL_USER}/install
  mv $__install_cfg_file /home/${OCP_INSTALL_USER}/install/
  chown -R ${OCP_INSTALL_USER}:${OCP_INSTALL_USER} /home/${OCP_INSTALL_USER}/install
  echo "creating ${OCP_INSTALL_USER}-user ssh key..."
  su - ${OCP_INSTALL_USER} -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
  echo "adding ${OCP_INSTALL_USER}-user ssh key to install-config.yaml..."
  su - ${OCP_INSTALL_USER} -c "echo -n \"sshKey: '\" >> install/install-config.yaml && cat ~/.ssh/id_rsa.pub | sed \"s/$/\'/g\" >> install/install-config.yaml"
  echo "backing up install-config.yaml..."
  su - ${OCP_INSTALL_USER} -c "cp install/install-config.yaml ~/install-config.yaml.backup"
  echo "creating manifest files..."
  su - ${OCP_INSTALL_USER} -c "cd install && openshift-install create manifests --dir=./"
  if [[ "$OCP_THREE_NODE_CLUSTER" != "yes" ]]; then
    #when using  user-provisioned infrastructure installation, master nodes are schedulable
    #make master unschedulable if not using three node cluster
    echo "configuring master nodes unschedulable..."
    su - ocp -c  "sed -i  \"s/mastersSchedulable: true/mastersSchedulable: false/g\" install/manifests/cluster-scheduler-02-config.yml"
  fi 
  echo "creating ignition files..."
  su - ${OCP_INSTALL_USER} -c "cd install && openshift-install create ignition-configs --dir=./"
  echo "copying ignition files to Apache server..."
  local htmlDir=/var/www/html
  chmod 644 /home/${OCP_INSTALL_USER}/install/*ign
  mv /home/${OCP_INSTALL_USER}/install/*ign $htmlDir/ignition
  #setting SELinux
  chcon -R -h -t httpd_sys_content_t $htmlDir/ignition

  echo "Setting up OpenShift install...done."

  echo "Install OpenShift by booting bootstrap, then masters, then workers...."
  echo "See documentation for instructions."

}