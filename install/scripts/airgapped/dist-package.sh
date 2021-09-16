function createLoadbalancerDistributionPackage
{
    echo "Creating load balancer distribution package..."
    local distDir=.
    #/tmp/lb-dist
    local distFilename=dist-lb.tar
    mkdir -p ${distDir}
    tar -P -cf ${distDir}/${distFilename} /usr/local/bin/gobetween
    tar -r -f ${distDir}/${distFilename} scripts/common/loadbalancer.sh
    tar -r -f ${distDir}/${distFilename} scripts/env/client_versions.sh
    
    local envFile=""
    if [[ ! -v OCP_VSPHERE_VIRTUAL_IP_API ]]; then
        envFile=upi-environment.sh
    else
        envFile=ipi-environment.sh
    fi
    echo "Using ${envFile}..."
    tar -r -f ${distDir}/${distFilename} ${envFile}

    #custom setup script
    cat > ${distDir}/setup-lb.sh << EOF
source \$(pwd)/scripts/common/loadbalancer.sh
source \$(pwd)/${envFile}
setupLoadBalancer
echo "Open HTTP/HTTPS ports..."
firewall-cmd --add-port=80/tcp --add-port=443/tcp --add-port=8080/tcp 
echo "Open OpenShift API ports..."
firewall-cmd --add-port=6443/tcp --add-port=22623/tcp 
#persist firewall settings
firewall-cmd --runtime-to-permanent
EOF

    tar -r -f ${distDir}/${distFilename} setup-lb.sh
    rm -f setup-lb.sh
    echo "Creating load balancer distribution package...done."
}

function createDistributionPackage
{
    echo "Creating distribution package..."

    local imageDir=$__container_image_dir
    mkdir -p $imageDir

    local scriptDir=$__dist_dir/
    mkdir -p $scriptDir

    downloadRHCOSBinaries $__dist_dir/rhcos

    # download useful git repositories
    downloadGitRepositories    
    
    #save container images
    downloadContainers
    echo "Saving container images..."
    podman images |grep -v "none\|TAG" |awk -v dir="${imageDir}" '{print "podman save -o " dir "/img_"  $3".tar " $1 ":" $2}' |sh     

    #copy this directory to script dir 
    echo "Copying these scripts..."
    cp -R . $scriptDir/

    #copy /usr/local/bin to $__dist_dir/bin dir
    echo "Copying binaries..."
    cp -R /usr/local/bin $__dist_dir

    createOfflineRepository

    echo "Creating distribution tar file..."
    local cdir=$(pwd)
    local tarFile=${cdir}/dist.tar
    cd ${__dist_dir}
    local base=$(basename $PWD)
    cd ..
    tar -cf ${tarFile} ${base}/
    cd $cdir

    echo "Creating distribution package...done."
    echo "Copy/move ${tarFile} to bastion."

}

function createOfflineRepository
{
    echo "creating local repository..."
    local localRepoDir=$__dist_dir/dnf-repository
    mkdir -p ${localRepoDir}
    local __current_dir=$(pwd)

    echo "downloading packages..."
    #downloads all packages and their dependenciens including those that are installed
    dnf --enablerepo=epel-testing download --alldeps --resolve --downloaddir ${localRepoDir} $__prereq_packages
    
    echo "creating repository..."
    cd $localRepoDir
    createrepo_c .
    repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
    createrepo_mod .
    cd $__current_dir 

    echo "creating local repository...done."

}
