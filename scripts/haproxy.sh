#omg.sh haproxy related functions and commands


if [[ "${__operation}" == "create-haproxy-server-wob" ]]; then
  echo "creating HAProxy server image without bootstrap..."
  cd ${__script_dir}/haproxy
  sh create_haproxy_server.sh nobootstrap
  cd ${__current_dir}
  echo "creating HAProxy server image without bootstrap...done."

fi

if [[ "${__operation}" == "create-haproxy-server" ]]; then
  echo "creating HAProxy server image..."
  cd ${__script_dir}/haproxy
  sh create_haproxy_server.sh
  cd ${__current_dir}
  echo "creating HAProxy server image...done."
fi

if [[ "${__operation}" == "prepare-haproxy" ]]; then
  check_role haproxy
  echo "creating local repo..."
  __repodir=$(pwd)/dist/local_repository
  __repofile=/etc/yum.repos.d/local2.repo
  cat > $__repofile << EOF
[localrepo]
name = Local RPM repo
baseurl = file://${__repodir}
enabled=1
gpgcheck=0
EOF
  echo "preparing haproxy..."
  prereq_install
  echo "loading container images..."
  #load images less than ~35MB, assumption is that haproxy is less than that
  ls -l dist/img_* | awk -v MAX=35870976 '/^-/ && $5 <= MAX { print $NF }' |awk '{print "podman load -i " $1}' |sh
  #ls -1 dist/img_* |awk '{print "podman load -i " $1}' |sh
  echo "extracting scripts..."
  tar -xf dist/scripts.tgz ${__script_dir}/haproxy
  echo "copying systemctl services to /etc/systemd/system/..."
  cp dist/${OCP_SERVICE_NAME_HAPROXY_SERVER}.service /etc/systemd/system/
  echo "start/stop haproxy:"
  echo "  systemctl start ${OCP_SERVICE_NAME_HAPROXY_SERVER}"
  echo "  systemctl stop ${OCP_SERVICE_NAME_HAPROXY_SERVER}"
  echo "create new haproxy image:"
  echo "  <configure IP addresses in config.sh>"
  echo "  sh omg.sh <create-haproxy-server | create-haproxy-server-wob>"

fi
