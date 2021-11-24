#install prereq packages from repository

__prereq_packages="podman \
                   jq \
                   nmap \
                   ntpstat \
                   bash-completion \
                   httpd-tools \
                   curl \
                   wget \
                   tcpdump \
                   tmux \
                   net-tools \
                   nfs-utils \
                   python3 \
                   git \
                   openldap \
                   openldap-clients \
                   openldap-devel \
                   chrony \
                   httpd \
                   bind \
                   bind-utils \
                   dnsmasq \
                   dhcp-server \
                   dhcp-client \
                   haproxy \
                   syslinux \
                   container* \
                   ansible \
                   expect \
                   ntfs-3g \
                   unzip \
                   skopeo \
                   "

function installPrereqs
{
    #prereq packages
    echo "Installing prereq packages..."
    echo "enabling Extra Packages for Enterprise Linux..."
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    dnf -y install --enablerepo=epel-testing $__prereq_packages

    echo "Installing prereq packages...done."
}

function installPrereqsBastion
{
    #prereq packages in airgapped bastion
    echo "Installing prereq packages..."
    dnf -y install $__prereq_packages

    echo "Installing prereq packages...done."
}


function installPrereqsForAirgapped
{
    echo "Installing prereq packages for distribution to airgap environment..."
    local __prereq_packages_jump="yum-utils createrepo libmodulemd modulemd-tools"
    #install tools to create local repository to be moved to airgapped bastion
    dnf -y copr enable frostyx/modulemd-tools-epel
    dnf -y install --enablerepo=epel-testing $__prereq_packages_jump
    echo "Installing prereq packages for distribution to airgap environment...done."
}