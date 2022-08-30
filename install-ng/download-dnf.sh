#!/bin/sh

#this scripts downloads prereqs from repository to be moved to airgapped environment

if [[ "$OMG_PREREQ_PACKAGES" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

set -e

REPO_NAME=local-repo
LOCAL_REPOSITORY_DIRECTORY=/tmp/$REPO_NAME

function downloadPrereqs
{
    #prereq packages
    echo "Downloading prereq packages..."
    
    mkdir -p ${LOCAL_REPOSITORY_DIRECTORY}
    local __current_dir=$(pwd)

    #downloads all packages and their dependenciens including those that are installed
    dnf -y install epel-release

    #install locally before downloading
    dnf -y install --enablerepo=epel-testing $OMG_PREREQ_PACKAGES

    dnf --enablerepo=epel-testing download --alldeps --resolve --downloaddir ${LOCAL_REPOSITORY_DIRECTORY} $OMG_PREREQ_PACKAGES
    
    echo "creating repository..."
    cd $LOCAL_REPOSITORY_DIRECTORY
    createrepo_c .
    repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
    createrepo_mod .

    echo "creating tar..."
    local base=$(basename $PWD)
    local filename=$base.tar
    cd ..
    tar -cf $filename $base
    mv $filename $__current_dir/
    cd $__current_dir 
    echo "creating tar...done"
    echo "copy/move $filename to airgapped environment."
    
    echo "Downloading prereq packages...done."
}


downloadPrereqs
