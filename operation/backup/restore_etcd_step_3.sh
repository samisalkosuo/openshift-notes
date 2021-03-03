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

echo "Restoring etcd STEP 3..."

echo "$__master2: Moving the etcd data directory..."
ssh core@${__master2} sudo mv /var/lib/etcd/ /tmp
echo "$__master3: Moving the etcd data directory..."
ssh core@${__master3} sudo mv /var/lib/etcd/ /tmp

echo "Restoring etcd STEP 3...done."
