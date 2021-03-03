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

echo "Restoring etcd STEP 4..."

echo "$__master1: Running restore script..."
ssh core@${__master1} sudo -E /usr/local/bin/cluster-restore.sh /home/core/backup

function restartKubelet
{
  local __host=$1
  echo "$__host: Restarting kubelet..."
  ssh core@${__host} sudo systemctl daemon-reload
  ssh core@${__host} sudo systemctl restart kubelet.service
  echo "$__host: Restarting kubelet...done."

}

for host in $__master_hosts; do
  restartKubelet $host
done 


echo "Restoring etcd STEP 4...done."

echo ""
echo "Rest of restore process is described:"
echo "https://docs.openshift.com/container-platform/4.6/backup_and_restore/disaster_recovery/scenario-2-restoring-cluster-state.html"
echo ""
echo "Continue restore from step 9 in the documentation."
