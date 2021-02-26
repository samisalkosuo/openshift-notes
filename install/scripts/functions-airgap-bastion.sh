function createLocalRepository
{
    echo "creating local repository..."
    local __repodir=$(pwd)/local_repository
    local __repofile=/etc/yum.repos.d/local2.repo
    cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF
    dnf clean all

}

function prepareAirgappedBastion
{
    echo "preparing bastion..."
    
    if [ ! -d ${__omg_mirror_registry_directory} ]; then
      error "mirror registry directory ${__omg_mirror_registry_directory} does not exist."
    fi

    local __rhcosDir=/var/www/html/rhcos
    if [ ! -d ${__rhcosDir} ]; then
      error "RHCOS directory ${__rhcosDir} does not exist."
    fi
    
    createLocalRepository
    dnf -y install $__prereq_packages

    echo "adding CA cert as trusted..."    
    cp ${__omg_cert_dir}/CA_$OCP_DOMAIN.crt /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract

    echo "loading container images..."
    ls -1 img_* |awk '{print "podman load -i " $1}' |sh

    echo "starting mirror regisry..."
    cp ${__omg_mirror_registry_systemd_service_name}.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl restart ${__omg_mirror_registry_systemd_service_name}
    systemctl enable ${__omg_mirror_registry_systemd_service_name}

    echo "copying binaries..."
    cp bin/* /usr/local/bin/

    echo "preparing bastion...done."
}
