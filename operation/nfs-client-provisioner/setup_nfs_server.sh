#this script sets up NFS server
#this is sample setup mainly for airgapped OpenShift install
#this script is based on https://www.linuxtechi.com/setup-nfs-server-on-centos-8-rhel-8/

function usageEnv
{
  echo "$1 env variable missing."
  echo "edit and source config.sh."
  exit 1
}

if [[ "$OCP_DHCP_NETWORK" == "" ]]; then
  usageEnv OCP_DHCP_NETWORK
fi

echo "Setting up NFS server..."

set -e

echo "Installing, starting and enabling NFS server..."
dnf install nfs-utils -y
systemctl start nfs-server
systemctl enable nfs-server

__nfs_dir=/mnt/nfs_share
echo "Creating NFS directory ${__nfs_dir}..."
mkdir -p ${__nfs_dir}

echo "Configuring ownership and permissions..."
chown -R nobody: ${__nfs_dir}
chmod -R 777 ${__nfs_dir}

echo "Restarting NFS server..."
systemctl restart nfs-server

echo "Setting exports..."
echo "${__nfs_dir} $OCP_DHCP_NETWORK/24(rw,sync,no_all_squash,root_squash)" > /etc/exports
exportfs -arv

echo "Opening firewall for NFS..."
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload

echo "Setting up NFS server...done."
