#!/bin/sh

#this scripts install prereqs from repository

if [[ "$OMG_PREREQ_PACKAGES" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi


function installPrereqs
{
    #prereq packages
    echo "Installing prereq packages..."
    echo "enabling Extra Packages for Enterprise Linux..."
    dnf -y install epel-release
    dnf -y install --enablerepo=epel-testing $OMG_PREREQ_PACKAGES

    echo "Installing prereq packages...done."
}



installPrereqs
