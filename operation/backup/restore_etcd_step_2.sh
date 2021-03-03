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

echo "Restoring etcd STEP 2..."

echo "$__master2: Moving the existing etcd pod file out of the kubelet manifest directory..."
ssh core@${__master2} sudo mv /etc/kubernetes/manifests/etcd-pod.yaml /tmp
echo "$__master2: Moving the existing Kubernetes API server pod file out of the kubelet manifest directory..."
ssh core@${__master2} sudo mv /etc/kubernetes/manifests/kube-apiserver-pod.yaml /tmp

echo "$__master3: Moving the existing etcd pod file out of the kubelet manifest directory..."
ssh core@${__master3} sudo mv /etc/kubernetes/manifests/etcd-pod.yaml /tmp
echo "$__master3: Moving the existing Kubernetes API server pod file out of the kubelet manifest directory..."
ssh core@${__master3} sudo mv /etc/kubernetes/manifests/kube-apiserver-pod.yaml /tmp


echo "Verify that the etcd pods the Kubernetes API server pods are stopped..."
echo "Use following commands..."
echo ssh core@${__master2} sudo crictl ps | grep etcd | grep -v operator
echo ssh core@${__master2} sudo crictl ps | grep kube-apiserver | grep -v operator
echo ssh core@${__master3} sudo crictl ps | grep etcd | grep -v operator
echo ssh core@${__master3} sudo crictl ps | grep kube-apiserver | grep -v operator
echo "When all commands show empty result, continue to STEP 3."

echo "Restoring etcd STEP 2...done."
