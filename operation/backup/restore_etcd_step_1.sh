#restores etcd as described in 
#https://docs.openshift.com/container-platform/4.6/backup_and_restore/disaster_recovery/scenario-2-restoring-cluster-state.html


function usage
{
  echo "Usage: $0 <master-node-name-1> <master-node-name-2> <master-node-name-3>"
  exit 1  
}

set -e

if [[ "$1" == "" ]]; then
  usage
fi

if [[ "$2" == "" ]]; then
  usage
fi

if [[ "$3" == "" ]]; then
  usage
fi

__master1=$1
__master2=$2
__master3=$3

__master_hosts="$__master1 $__master2 $__master3"
function checkHost
{
    local __host=$1
    ssh core@${__host} echo "OK" > /dev/null
    #if ssh fails, script exits because "set -e" was set
    echo "$__host: OK"
}

echo "Restoring etcd STEP 1..."

echo "Checking backup files..."
__count=$(ls -latr snapshot_* |wc |awk '{print $1}')
if [[ "$__count" == "1" ]]; then
  echo "snapshot file found."
else
  echo "ERROR"
  echo "More than one snapshot file found."
  echo "Not allowed. Use only one snapshot file."
  exit 1
fi

__count=$(ls -latr static_kuberesources_* |wc |awk '{print $1}')
if [[ "$__count" == "1" ]]; then
  echo "static_kuberesources file found."
else
  echo "ERROR"
  echo "More than one static_kuberesources file found."
  echo "Not allowed. Use only one static_kuberesources file."
  exit 1
fi

echo "Checking hosts..."
for masterHost in $__master_hosts; do
  checkHost $masterHost
done 

__backup_dir=/home/core/backup
echo "Copy backup files to ${__master1}..."
ssh core@${__master1} mkdir -p ${__backup_dir}
scp snapshot_* core@${__master1}:${__backup_dir}/
scp static_kuberesources_* core@${__master1}:${__backup_dir}/
echo "Copy backup files to ${__master1}...done."



echo "Restoring etcd STEP 1...done."
