function installPrereqs
{
    #prereq packages
    echo "Installing prereq packages..."
    echo "enabling Extra Packages for Enterprise Linux..."
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    __packages="podman jq nmap ntpstat bash-completion httpd-tools curl wget tmux net-tools nfs-utils python3 git openldap openldap-clients openldap-devel yum-utils createrepo libmodulemd modulemd-tools httpd bind dnsmasq dhcp-server haproxy syslinux"
    dnf -y install --enablerepo=epel-testing $__packages
    echo "Installing prereq packages...done."

}

function configureApache
{
    local htmlDir=/var/www/html
    mkdir -p $htmlDir/rhcos
    mkdir -p $htmlDir/ignition
    #setting SELinux
    chcon -R -h -t httpd_sys_content_t $htmlDir
    echo "Configuring Apache..."
    set +e
    cat /etc/httpd/conf/httpd.conf |grep "Listen 8080" > /dev/null
    local rv=$?
    set -e
    if [ $rv -eq 1 ]; then
      echo "Changing Apache port to ${OCP_APACHE_PORT}..."
      sed -ibak "s/Listen 80/Listen $OCP_APACHE_PORT/g" /etc/httpd/conf/httpd.conf
    fi

    downloadRHCOSBinaries
    echo "Starting and enabling Apache server..."
    systemctl daemon-reload
    systemctl enable httpd
    systemctl restart httpd
    echo "Configuring Apache...done."

}


function configureNTPServer
{
    __ntp_config_file=/etc/chrony.conf
    if [ -f $__ntp_config_file ]; then    
        set +e
        cat $__ntp_config_file |grep "^local stratum 10" > /dev/null
        local rv=$?
        set -e
        if [ $rv -eq 0 ]; then
            echo "NTP server chrony seems to be configured."
        else
            echo "Configuring chrony as NTP server in this host..."
            echo "" >> $__ntp_config_file
            echo "#Local NTP server configuration created by $0" >> $__ntp_config_file
            echo "local stratum 10" >> $__ntp_config_file
            echo "allow all" >> $__ntp_config_file
            echo "Starting and enabling NTP server..."
            systemctl daemon-reload
            systemctl enable chronyd
            systemctl restart chronyd
            echo "Configuring chrony as NTP server in this host...done."
        fi
    else
        error "NTP configuration file $__ntp_config_file does not exist."
    fi
}
