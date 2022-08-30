#!/bin/sh

#this scripts creates local repo from downloaded packages
#to be used in airgapped bastion

if [[ "$OMG_PREREQ_PACKAGES" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

REPO_NAME=local-repo
PKG_NAME=$REPO_NAME.tar

function installLocalRepo
{
    #prereq packages
    echo "Installing local repository..."
    local __repofile=/etc/yum.repos.d/$REPO_NAME.repo
    if [[ -f "$__repofile" ]]
    then
        echo "$__repofile exists."
        echo "Not creating again."
        return
    fi
    if [[ ! -f "$PKG_NAME" ]]
    then
        echo "$PKG_NAME does not exist."
        return
    fi
    
    echo "Removing and creating backup of /etc/yum.repos.d/..."
    local timestamp=$(date "+%Y%m%d%H%M%S")
    mv /etc/yum.repos.d /etc/yum.repos.d_backup_${timestamp}
    mkdir -p /etc/yum.repos.d
    echo "Removing and creating backup of /etc/yum.repos.d/...done."
    
    #extracts packaged repo
    tar -xf $PKG_NAME
    local __repodir=$(pwd)/${REPO_NAME}
    cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF


    echo "Installing local repository...done."
}

function installPackages
{
    echo "Installing packages..."
    dnf -y install  $OMG_PREREQ_PACKAGES --allowerasing --skip-broken
    
    dnf clean all

    echo "Installing packages...done."

}


installLocalRepo
installPackages
