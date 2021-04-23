#functions to package files in jump server to be transferred
#to airgapped bastion

__dist_dir=dist

function createOfflineRepository
{
    echo "creating local repository..."
    mkdir -p $__dist_dir
    local __current_dir=$(pwd)

    echo "downloading packages..."
    local __repodir=${__dist_dir}/local_repository
    mkdir -p $__repodir 
    #downloads all packages and their dependenciens including those that are installed
    dnf --enablerepo=epel-testing download --alldeps --resolve --downloaddir $__repodir $__prereq_packages
    
    echo "creating repository..."
    cd $__repodir
    createrepo_c .
    repo2module . --module-name airgapped --module-stream devel --module-version 100 --module-context local
    createrepo_mod .
    cd $__current_dir 

    echo "creating local repository...done."

}

function packageFilesForBastion
{
    echo "creating dist-package to airgapped bastion..."
    
    echo "saving container images..."
    podman images |grep -v "none\|TAG" |awk -v dir="${__dist_dir}" '{print "podman save -o " dir "/img_"  $3".tar " $1 ":" $2}' |sh     
    
    echo "copy mirror-registry service file..."
    cp /etc/systemd/system/${__omg_mirror_registry_systemd_service_name}.service ${__dist_dir}/ 

    echo "copying binaries..."
    mkdir -p $__dist_dir/bin
    cp /usr/local/bin/oc ${__dist_dir}/bin/
    cp /usr/local/bin/kubectl ${__dist_dir}/bin/
    cp /usr/local/bin/kubeterminal* ${__dist_dir}/bin/
    cp /usr/local/bin/openshift-install ${__dist_dir}/bin/

    echo "copying pull-secret bundle..."
    if [ ! -f run-omg/pull-secrets/pull-secret-bundle.json ]; then
      error "file run-omg/pull-secrets/pull-secret-bundle.json does not exist."
    fi
    cp ${OCP_PULL_SECRET_FILE} ${OCP_PULL_SECRET_FILE}.original
    cp run-omg/pull-secrets/pull-secret-bundle.json ${OCP_PULL_SECRET_FILE}

    echo "packaging scripts..."      
    cp -R scripts templates ${__omg_runtime_dir} *.sh $OCP_PULL_SECRET_FILE  ${__dist_dir}/ 
    tar -cf dist.tar ${__dist_dir}/

    echo "downloading RHCOS files..."
    downloadRHCOSBinaries
    echo "packaging RHCOS files..."
    tar -P -cf rhcos.tar /var/www/html/rhcos/

    echo "packaging mirror registry..."
    tar -P -cf mirror-registry.tar $__omg_mirror_registry_directory 

    echo "creating distribution files...done."
    echo "copy/move following files to bastion server:"
    echo "  dist.tar"
    echo "  rhcos.tar"    
    echo "  mirror-registry.tar" 

    echo "creating dist-package to airgapped bastion...done."
}

function createHAProxyDistPackage
{
    echo "creating dist-package for HAProxy..."
    local __local_repository_dir=local_repository
    if [ ! -d ${__local_repository_dir} ]; then
      __local_repository_dir=dist/local_repository
      if [ ! -d ${__local_repository_dir} ]; then
        error "local_repository directory does not exist."
      else
        #if local repo dir is in dist-dir, move it to .
        #so that other functions work correctly
        mv ${__local_repository_dir} .
        __local_repository_dir=local_repository
      fi
    fi
    #tar -cf dist_haproxy.tar local_repository/ *sh scripts/ templates/
    #add dummy pull-secret.json
    echo "dummy pull-secret.json so that OCP_PULL_SECRET_FILE points to fle in haproxy server" > dummy_pull_secret
    tar --transform='flags=r;s|dummy_pull_secret|pull-secret.json|' -cf dist_haproxy.tar dummy_pull_secret ${__local_repository_dir}/ *sh scripts/ templates/
    echo "copy/move following file to haproxy server:"
    echo "  dist_haproxy.tar"
    echo "creating dist-package for HAProxy...done."
}
