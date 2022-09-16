#!/bin/sh

#setup NTP server


if [[ "$OMG_NTP_SERVER_IP" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

function setupNTPServer
{
    local __ntp_config_file=/etc/chrony.conf
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

            # echo "Open NTP port..."
            # firewall-cmd --add-port=123/udp
            # #persist firewall settings
            # firewall-cmd --runtime-to-permanent
        fi
    else
        error "NTP configuration file $__ntp_config_file does not exist. Can not setup NTP server."
    fi
}

setupNTPServer
