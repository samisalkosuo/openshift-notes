#omg.sh boot services commands

if [[ "${__operation}" == "create-dhcp-pxe-server" ]]; then
  echo "creating DHCP/PXE server images..."
  cd ${__script_dir}/boot-services
  sh create_dhcp_pxe_image.sh
  cd ${__current_dir}
  echo "creating DHCP/PXE server images...done."
fi

if [[ "${__operation}" == "create-dns-server" ]]; then
  echo "creating DNS server images..."
  cd ${__script_dir}/boot-services
  sh create_dns_image.sh
  cd ${__current_dir}
  echo "creating DNS server images...done."
fi

if [[ "${__operation}" == "create-apache-rhcos-server" ]]; then
  echo "creating Apache for RHCOS images..."
  cd ${__script_dir}/boot-services
  sh create_apache_image.sh
  cd ${__current_dir}
  echo "creating Apache for RHCOS images...done."
fi


if [[ "${__operation}" == "create-ntp-server" ]]; then
  echo "creating NTP server image..."
  cd ${__script_dir}/ntp-server
  sh create_ntp_server_image.sh
  cd ${__current_dir}
  echo "creating NTP server image...done."
fi
