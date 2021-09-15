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