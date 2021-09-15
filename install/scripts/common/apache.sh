function setupApache
{
    local htmlDir=/var/www/html
    mkdir -p $htmlDir/rhcos
    mkdir -p $htmlDir/ignition
    #setting SELinux
    chcon -R -h -t httpd_sys_content_t $htmlDir
    echo "Configuring Apache..."
    set +e
    cat /etc/httpd/conf/httpd.conf |grep "Listen ${OCP_APACHE_PORT}" > /dev/null
    local rv=$?
    set -e
    if [ $rv -eq 1 ]; then
      echo "Changing Apache port to ${OCP_APACHE_PORT}..."
      sed -ibak "s/Listen 80/Listen ${OCP_APACHE_PORT}/g" /etc/httpd/conf/httpd.conf
    fi

    #creating index file
    cat > /var/www/html/index.html << EOF
<html>
<body>
<a href="./rhcos/">RHCOS binaries</a><br/>
<a href="./ignition/">Ignition files</a><br/>
</html>
</body>
EOF

    echo "Starting and enabling Apache server..."
    systemctl daemon-reload
    systemctl enable httpd
    systemctl restart httpd
    echo "Configuring Apache...done."
}
