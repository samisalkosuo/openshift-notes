#functions related to openshift configuration

#TODO: add functions here and add to omg scripts

function openshiftCOnfigureCommandUsage
{
    echo "Usage: $0 ocp-config <command>"
    echo ""
    echo "Command:"
    echo "  disable-default-operator-hub-sources - Creates and snapshots bootstrap, master and worker VMs."
    exit 1
}

function openshiftConfigureCommand
{
    if [[ "$1" == "" ]]; then
        openshiftCOnfigureCommandUsage
    fi
    case "$1" in
        disable-default-operator-hub-sources)
            disableDefaultOperatorHubSources
        ;;
        *)
            openshiftCOnfigureCommandUsage
        ;;
    esac

}

function disableDefaultOperatorHubSources
{
  (export KUBECONFIG=$(getKubeConfig); oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]')
}
