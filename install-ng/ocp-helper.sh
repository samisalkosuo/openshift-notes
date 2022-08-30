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
  echo "  nodes                        - Watch OpenShift nodes."
  echo "  csr                          - Watch CSRs."
  echo "  csr-approve                  - Approve all pending CSRs."
  echo "  clusteroperators             - Watch OpenShift cluster operators."
  echo "  disable-operatorhub-sources  - Disable default OperatorHub sources in airgapped environment."
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
    *)
        usage
        ;;
esac
