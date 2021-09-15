#functions to prepare airgapped bastion

function createMirrorRegistry
{
    echo "Creating mirror registry..."

    echo "Creating CA cert and self-signed cert..."
    echo "Creating CA cert for domain '$OCP_DOMAIN'..."
    createCACert $OCP_DOMAIN
    echo "Creating cert for registry '${__mirror_registry_base_name}.${OCP_DOMAIN}'..."
    createRegistryCert $OCP_DOMAIN
    echo "Creating CA cert and self-signed cert...done."

    createRegistryContainerAndService

    echo "Creating mirror registry...done."
}

function createLocalDNFRepository
{
    echo "Creating local repository..."
    local __repodir=${__dist_dir}/dnf-repository
    echo "Removing and creating backup of /etc/yum.repos.d/..."
    mv /etc/yum.repos.d /etc/yum.repos.d_backup
    mkdir -p /etc/yum.repos.d
    echo "Removing and creating backup of /etc/yum.repos.d/...done."
    local __repofile=/etc/yum.repos.d/local2.repo
    cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF
    dnf clean all
    echo "Creating local repository...done."
}

function loadContainerImages
{
    #load all container images
    echo "Loading container images..."
    local cdir=$(pwd)
    cd $__container_image_dir
    ls -1 *.tar |awk '{print "podman load -i " $1}' |sh
    cd $cdir
    echo "Loading container images...done"

}

function copyBinariesToUsrLocalBin
{
    echo "Copy binaries to /usr/local/bin..."
    cp -R ${__dist_dir}/bin/* /usr/local/bin/
    echo "Copy binaries to /usr/local/bin...done."
}

function copyRHCOSBinaries
{
    local htmlDir=/var/www/html
    echo "Copy RHCOS binaries to $htmlDir..."
    mkdir -p $htmlDir/rhcos
    cp ${__dist_dir}/rhcos/* $htmlDir/rhcos
    echo "Copy RHCOS binaries to $htmlDir...done."

}