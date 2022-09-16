if [[ "$OMG_OCP_CLUSTER_NAME" == "" ]]; then
  echo "Environment variables are not set."
  exit 1
fi

set -e

#OpenShift install dir, used while installing OpenShift
#holds kubeconfig authentication file in auth-subdirectory
__dir_suffix=${OMG_OCP_CLUSTER_NAME}.${OMG_OCP_DOMAIN}
__openshift_install_dir=~/ocp-install-${__dir_suffix}


function usage
{
  echo "OpenShift oc helper commands."
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo ""
  echo "  nodes                                 - Watch OpenShift nodes."
  echo "  csr                                   - Watch CSRs."
  echo "  csr-approve                           - Approve all pending CSRs."
  echo "  clusteroperators                      - Watch OpenShift cluster operators."
  echo "  disable-operatorhub-sources           - Disable default OperatorHub sources in airgapped environment."
  echo "  place-router-pods <worker1> <worker2> - Placer router pods to given worker nodes."
  echo "  set-default-storageclass <sc-name>    - Set give storageclass as default."
  exit 1
}


function getKubeConfig
{
    local __kubeconfig="notfound"

    if [ -d "${__openshift_install_dir}" ]
    then
      __kubeconfig="${__openshift_install_dir}/auth/kubeconfig"
    fi

    echo $__kubeconfig
}

function ocpGetClusterOperators
{
    
    (export KUBECONFIG=$(getKubeConfig); watch -n3 oc get clusteroperators)
}

function ocpGetNodes
{
  (export KUBECONFIG=$(getKubeConfig); watch -n3 oc get nodes)

}

function ocpGetCSR
{    
    (export KUBECONFIG=$(getKubeConfig); watch -n3 oc get csr)
}

function ocpApproveAllCSRs
{
    (export KUBECONFIG=$(getKubeConfig); oc get csr |grep Pending |awk '{print "oc adm certificate approve " $1}' |sh)
    
}

function disableOperatorHubSources
{
    (export KUBECONFIG=$(getKubeConfig); \
    oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]')
}

function placeRouterPods
{
    if [[ "$1" == "" ]]; then
        echo "Worker 1 node name not given."
        exit 1
    fi
    if [[ "$2" == "" ]]; then
        echo "Worker 2 node name not given."
        exit 1
    fi
    local worker1=$1
    local worker2=$2
    (export KUBECONFIG=$(getKubeConfig); \
     oc label node $worker1 nodeType=router; \
     oc label node $worker2 nodeType=router; \
     oc patch namespace openshift-ingress -p '{"metadata":{"annotations":{"openshift.io/node-selector":"nodeType=router"}}}'; \
     oc -n openshift-ingress get pods --no-headers |awk '{print "oc -n openshift-ingress delete pod " $1 " &"}' | sh; \
     )

}

#download specified images
function setDefaultStorageClass
{
    if [[ "$1" == "" ]]; then
        echo "Storageclass not given."
        exit 1
    fi
    local storageClass=$1
    oc patch storageclass $storageClass -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
}


case "$1" in
    nodes)
        ocpGetNodes
    ;;
    csr)
        ocpGetCSR
    ;;
    csr-approve)
        ocpApproveAllCSRs
    ;;
    clusteroperators)
        ocpGetClusterOperators
    ;;
    disable-operatorhub-sources)
        disableOperatorHubSources
    ;;
    place-router-pods)
        placeRouterPods $2 $3
    ;;
    set-default-storageclass)
        setDefaultStorageClass $2
    ;;
    *)
        usage
    ;;
esac
