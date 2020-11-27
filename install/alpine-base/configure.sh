#!/bin/sh

#configure alpine-base image

#configure Apache:
#  add server name to apache config
#  configure logging to system out
#  change document root to /var/www/apache

__apache_config_file=/etc/apache2/httpd.conf
mkdir /var/www/apache
sed -i s@/var/www/localhost/htdocs@/var/www/apache@g ${__apache_config_file}
cat >> ${__apache_config_file} << EOF
ServerName apache
ErrorLog /dev/stderr
CustomLog /dev/stdout combined
EOF

