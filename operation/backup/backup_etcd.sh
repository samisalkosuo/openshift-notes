#this scripts backs up OpenShift etcd and copies backup files to current directory

#script must be run as ocp-user (or other) that has SSH access to nodes

function usage
{
  echo "Usage: $0 <master-node>"
  exit 1  
}

set -e

if [[ "$1" == "" ]]; then
  usage
fi

__master_node=$1
__backup_dir=/home/core/assets/backup
__snapshot_file_prefix=snapshot
__kuberesources_file_prefix=static_kuberesources

echo "Running backup script on ${__master_node}..."
ssh core@${__master_node} sudo /usr/local/bin/cluster-backup.sh ${__backup_dir}
#moving and changing ownership of backup files
ssh core@${__master_node} sudo mv ${__backup_dir}/${__snapshot_file_prefix}* /tmp 
ssh core@${__master_node} sudo mv ${__backup_dir}/${__kuberesources_file_prefix}* /tmp
ssh core@${__master_node} sudo chown core:core /tmp/${__snapshot_file_prefix}*
ssh core@${__master_node} sudo chown core:core /tmp/${__kuberesources_file_prefix}*
echo "Copying backup files to current directory..."
scp core@${__master_node}:/tmp/${__snapshot_file_prefix}* .
scp core@${__master_node}:/tmp/${__kuberesources_file_prefix}* .
echo "Deleting backup files from ${__master_node}..."
ssh core@${__master_node} sudo rm -rf /home/core/assets/backup
ssh core@${__master_node} sudo rm -rf /tmp/${__snapshot_file_prefix}*
ssh core@${__master_node} sudo rm -rf /tmp/${__kuberesources_file_prefix}*

echo "Running backup script on ${__master_node}...done."
