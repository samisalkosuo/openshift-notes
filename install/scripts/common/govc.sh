#functions related to vmware
#uses govc


#variables for VMs
__master_cpu=8
__master_ram=16384
__master_disk=120GB
__worker_cpu=16
__worker_ram=32768
__worker_disk=120GB

function govcCommandUsage
{
    echo "Usage: $0 govc <command>"
    echo ""
    echo "Command:"
    echo "  create-vms                                      - Creates and snapshots bootstrap, master and worker VMs."
    echo "  get-macs                                        - Prints MAC addresses of VMs."
    echo "  revert-vms                                      - Reverts bootstrap, master and worker VMs to initial snapshot."
    echo "  delete-vms                                      - Deletes bootstrap, master and worker VMs."
    echo "  power-on  <bootstrap | masters | workers | all> - Powers on chosen VMs."
    echo "  power-off <bootstrap | masters | workers | all> - Powers off chosen VMs."
    exit 1
}

function govcCommand
{
    if [[ "$1" == "" ]]; then
        govcCommandUsage  
    fi
    case "$1" in
        create-vms)
            createVMs
        ;;
        revert-vms)
            revertVMs
        ;;
        delete-vms)
            deleteVMs
        ;;
        get-macs)
            getMacs
        ;;
        power-on)
            powerOn $2
        ;;
        power-off)
            powerOff $2
        ;;
        *)
            govcCommandUsage
        ;;
    esac

}

function powerOn
{    
    local vms=$1
    echo "Powering on $vms..."
    if [[ "$vms" == "all" ]]; then
      powerAction ON bootstrap
      powerAction ON masters
      powerAction ON workers
    else
      powerAction ON $vms
    fi
    echo "Powering on $vms...done."
}

function powerOff
{    
    local vms=$1
    echo "Powering off $vms..."
    if [[ "$vms" == "all" ]]; then
      powerAction OFF bootstrap
      powerAction OFF masters
      powerAction OFF workers
    else
      powerAction OFF $vms
    fi

    echo "Powering off $vms...done."
}


function powerAction
{    
    local action=$1
    local vms=$2
    local options=""
    case "$action" in
        ON)
            options="-on"
        ;;
        OFF)
            options="-off -force"
        ;;
    esac
    case "$vms" in
        bootstrap)
            local hostInfo=($OCP_NODE_BOOTSTRAP)
            local hostName=${hostInfo[0]}
            govc vm.power ${options} $hostName-$OCP_CLUSTER_NAME
        ;;
        masters)
            local hostInfo=($OCP_NODE_MASTER_01)
            local master1=${hostInfo[0]}
            hostInfo=($OCP_NODE_MASTER_02)
            local master2=${hostInfo[0]}
            hostInfo=($OCP_NODE_MASTER_03)
            local master3=${hostInfo[0]}
            govc vm.power ${options} $master1-$OCP_CLUSTER_NAME $master2-$OCP_CLUSTER_NAME $master3-$OCP_CLUSTER_NAME
        ;;
        workers)
            #get worker environment variables
            local var=$OCP_NODE_WORKER_HOSTS
            local SAVEIFS=$IFS   # Save current IFS
            IFS=$';'      # Change IFS to ;
            local arr=($var) # split to array 
            IFS=$SAVEIFS   # Restore IFS

            for _hostInfo in "${arr[@]}"
            do
                local hostInfo=($_hostInfo)
                local hostName=${hostInfo[0]}
                if [[ "${hostName}" != "" ]]; then
                    govc vm.power ${options} ${hostName}-$OCP_CLUSTER_NAME
                fi
            done
        ;;
    esac
    
}


function printNewEnvironmentVariable
{
    local variableName=$1
    local hostInfo=($2)
    local hostName=${hostInfo[0]}
    local hostIP=${hostInfo[1]}
    local mac=""
    if [[ "${hostName}" != "" ]]; then
        mac=$(govc vm.info -e -r -json ${hostName}-$OCP_CLUSTER_NAME |jq ".. | .MacAddress?  | select(. != null)" | sed "s/\"//g" )
        echo "export ${variableName}=\"${hostName} ${hostIP} ${mac}\""
    fi
}

function getMacs
{
    #get MACs
    echo "#Replace environment variables in environment.sh"
    #get bootstrap and master environment variables
    printNewEnvironmentVariable OCP_NODE_BOOTSTRAP "$OCP_NODE_BOOTSTRAP"
    printNewEnvironmentVariable OCP_NODE_MASTER_01 "$OCP_NODE_MASTER_01"
    printNewEnvironmentVariable OCP_NODE_MASTER_02 "$OCP_NODE_MASTER_02"
    printNewEnvironmentVariable OCP_NODE_MASTER_03 "$OCP_NODE_MASTER_03"

    #get worker environment variables
    local var=$OCP_NODE_WORKER_HOSTS
    local SAVEIFS=$IFS   # Save current IFS
    IFS=$';'      # Change IFS to ;
    local arr=($var) # split to array 
    IFS=$SAVEIFS   # Restore IFS

    echo "export OCP_NODE_WORKER_HOSTS=\" \\"
    for _hostInfo in "${arr[@]}"
    do
        local hostInfo=($_hostInfo)
        local hostName=${hostInfo[0]}
        if [[ "${hostName}" != "" ]]; then
            local hostIP=${hostInfo[1]}
            local mac=$(getSingleMac "$_hostInfo")
            echo "${hostName} ${hostIP} ${mac}  ; \\"
        fi
    done
    echo "\""

}

function createVMs
{
    createSingleVM "$OCP_NODE_BOOTSTRAP" ${__master_cpu} ${__master_ram} ${__master_disk}
    createSingleVM "$OCP_NODE_MASTER_01" ${__master_cpu} ${__master_ram} ${__master_disk}
    createSingleVM "$OCP_NODE_MASTER_02" ${__master_cpu} ${__master_ram} ${__master_disk}
    createSingleVM "$OCP_NODE_MASTER_03" ${__master_cpu} ${__master_ram} ${__master_disk}
    operateOnWorkers create
}

function revertVMs
{
    revertSingleVM "$OCP_NODE_BOOTSTRAP"
    revertSingleVM "$OCP_NODE_MASTER_01"
    revertSingleVM "$OCP_NODE_MASTER_02"
    revertSingleVM "$OCP_NODE_MASTER_03"
    operateOnWorkers revert
}


function deleteVMs
{
    deleteSingleVM "$OCP_NODE_BOOTSTRAP"
    deleteSingleVM "$OCP_NODE_MASTER_01"
    deleteSingleVM "$OCP_NODE_MASTER_02"
    deleteSingleVM "$OCP_NODE_MASTER_03"
    operateOnWorkers delete

}

function operateOnWorkers
{
    local action=$1
    #worker nodes
    local var=$1
    local SAVEIFS=$IFS   # Save current IFS
    IFS=$';'      # Change IFS to ;
    local arr=($OCP_NODE_WORKER_HOSTS) # split to array 
    IFS=$SAVEIFS   # Restore IFS

    case "$action" in
        create)
            for hostInfo in "${arr[@]}"
            do
                createSingleVM "$hostInfo" ${__worker_cpu} ${__worker_ram} ${__worker_disk}
            done
        ;;
        revert)
            for hostInfo in "${arr[@]}"
            do
                revertSingleVM "$hostInfo"
            done
        ;;
        delete)
            for hostInfo in "${arr[@]}"
            do
                deleteSingleVM "$hostInfo"
            done
        ;;
        *)
            echo "Unknown action."
        ;;
    esac

}

function createSingleVM
{
    local hostInfo=($1)
    if [[ "${hostInfo[0]}" != "" ]]; then
        local cpu=$2
        local ram=$3
        local disk=$4
        local vmName=${hostInfo[0]}-$OCP_CLUSTER_NAME
        echo "Creating $vmName... Cores ${cpu}, RAM ${ram}, disk ${disk}..."
        govc vm.create -m ${ram} -c ${cpu} -disk ${disk} -g coreos64Guest -on=false -net.adapter vmxnet3 $vmName
        echo "Creating $vmName... Cores ${cpu}, RAM ${ram}, disk ${disk}...done."
        echo "Settings disk.enableUUID=TRUE..."
        govc vm.change -e="disk.enableUUID=1" -vm=${vmName}
        echo "Settings disk.enableUUID=TRUE...done."
        echo "Snapshotting..."
        govc snapshot.create -vm $vmName -d "Empty VM, no OS" empty-vm
        echo "Snapshotting...done."
        echo "Creating $vmName...done."
    fi
}

function revertSingleVM
{
    local hostInfo=($1)
    if [[ "${hostInfo[0]}" != "" ]]; then
        local vmName=${hostInfo[0]}-$OCP_CLUSTER_NAME
        echo "Reverting $vmName..."
        govc snapshot.revert -vm $vmName -s=false empty-vm
        echo "Reverting $vmName...done."
    fi
}


function deleteSingleVM
{
    local hostInfo=($1)
    if [[ "${hostInfo[0]}" != "" ]]; then
        local vmName=${hostInfo[0]}-$OCP_CLUSTER_NAME
        echo "Deleting $vmName..."
        govc vm.destroy $vmName
        echo "Deleting $vmName...done."
    fi
}

function getSingleMac
{
    #get mac address from hostInfo string like "worker01 192.168.47.111 00:50:56:b3:00:16"
    local hostInfo=($1)
    if [[ "${hostInfo[0]}" != "" ]]; then
        local rv=$(govc vm.info -e -r -json ${hostInfo[0]}-$OCP_CLUSTER_NAME |jq ".. | .MacAddress?  | select(. != null)" | sed "s/\"//g" )
        echo $rv
    fi
}
