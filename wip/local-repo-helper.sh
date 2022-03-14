#!/bin/bash

#prereq packages and useful tools
#these and prereqs are downloaded
PREREQ_PACKAGES="jq \
                podman \
                container* \
                nmap \
                bash-completion \
                httpd-tools \
                curl \
                wget \
                tcpdump \
                dnsmasq \
                haproxy \
                tmux \
                dnsmasq \
                openldap \
                openldap-clients \
                openldap-devel \
                net-tools \
                nfs-utils \
                python3 \
                git \
                httpd \
                ntpstat \
                chrony \
                bind \
                bind-utils \
                dhcp-server \
                dhcp-client \
                expect \
                ansible \
                ntfs-3g \
                unzip \
                skopeo \
                syslinux \
                haproxy \
                yum-utils \
                createrepo \
                libmodulemd \
                modulemd-tools \
                cloud-utils-growpart \
                gdisk \
                "


LOCAL_REPOSITORY_DIRECTORY=offline-repository
LOCAL_REPOSITORY_FILE=local_repository.repo

function usage
{
  echo "Local/offline repository helper."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo "  create-offline   - Create and package repository of selected packages to be copied to airgapped server."
  echo "  create-local     - Create local repository of selected packages."
  echo "  install-all      - Install all packages."
  exit 1
}

function error
{
  echo "ERROR: $1"
  exit 2
}

set -e

#download packages to be used in offline repository
function createOfflineRepository
{
    echo "creating local repository..."

    mkdir -p ${LOCAL_REPOSITORY_DIRECTORY}
    local __current_dir=$(pwd)

    echo "downloading packages..."
    #downloads all packages and their dependenciens including those that are installed
    dnf --enablerepo=epel-testing download --alldeps --resolve --downloaddir ${LOCAL_REPOSITORY_DIRECTORY} $PREREQ_PACKAGES
    
    echo "creating repository..."
    cd $LOCAL_REPOSITORY_DIRECTORY
    createrepo_c .
    repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
    createrepo_mod .
    cd $__current_dir 

    echo "creating local repository...done."

}

function createLocalRepositoryFile
{
    echo "Creating local repository..."
    echo "Removing and creating backup of /etc/yum.repos.d/..."
    local timestamp=$(date "+%Y%m%d%H%M%S")
    mv /etc/yum.repos.d /etc/yum.repos.d_backup_${timestamp}
    mkdir -p /etc/yum.repos.d
    echo "Removing and creating backup of /etc/yum.repos.d/...done."
    local __repofile=/etc/yum.repos.d/$LOCAL_REPOSITORY_FILE
    local __repodir=$(pwd)/${LOCAL_REPOSITORY_DIRECTORY}
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

function createAndPackageOfflineRepo
{
    if [[ -d "$LOCAL_REPOSITORY_DIRECTORY" ]]
    then
        echo "$LOCAL_REPOSITORY_DIRECTORY exists."
        echo "Not downloading again."
        #return
    fi
    createOfflineRepository
    local offlineFile=$LOCAL_REPOSITORY_DIRECTORY.tar
    tar -cf ${offlineFile} $0 $LOCAL_REPOSITORY_DIRECTORY
    echo "Offline repository created: ${offlineFile}"
    echo ""
    echo "Move/copy ${offlineFile} to airgapped server."
}

function createLocalRepository
{
    if [[ ! -d "$LOCAL_REPOSITORY_DIRECTORY" ]]
    then
        error "$LOCAL_REPOSITORY_DIRECTORY does not exist."
    fi    
    local __repofile=/etc/yum.repos.d/LOCAL_REPOSITORY_FILE
    if [[ -f "$__repofile" ]]
    then
        echo "$__repofile exists."
        echo "Not creating again."
        return
    fi
    createLocalRepositoryFile
}

function installAllPackages
{
    dnf -y install $PREREQ_PACKAGES
}

case "$1" in
    create-offline)
        createAndPackageOfflineRepo
        ;;
    create-local)
        createLocalRepository
        ;;
    install-all)
        installAllPackages
        ;;
    *)
        usage
        ;;
  esac
