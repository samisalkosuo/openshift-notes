function downloadContainers
{
    echo "Dowloading containers..."
    local containers=($__container_images) # split to array 

    for container in "${containers[@]}"
    do
        podman pull $container
    done

    echo "Dowloading containers...done."
}

function downloadGitRepositories
{
    echo "Dowloading git repositories..."
    
    #create git repo dir
    mkdir -p $__gitrepo_dir
    
    local repos=($__git_repositories) # split to array 
    local cdir=$(pwd)
    
    cd $__gitrepo_dir
    for repo in "${repos[@]}"
    do
        git clone $repo
    done
    cd $cdir
    echo "Dowloading git repositories...done."
}