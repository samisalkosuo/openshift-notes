#download Quay registry
#and registry container

REGISTRY_IMAGES_DIR=registry-images

mkdir -p $REGISTRY_IMAGES_DIR

set -e 

function downloadRegistryImages
{
    echo "Downloading registry images..."
    podman pull docker.io/library/registry:2
    podman save docker.io/library/registry:2 > $REGISTRY_IMAGES_DIR/registry-2.tar

    podman pull docker.io/library/postgres:10.12
    podman save docker.io/library/postgres:10.12 > $REGISTRY_IMAGES_DIR/postgres-10.12.tar

    podman pull docker.io/library/redis:5.0.14
    podman save docker.io/library/redis:5.0.14 > $REGISTRY_IMAGES_DIR/redis-5.0.14.tar

    podman pull quay.io/projectquay/quay:3.7.6
    podman save quay.io/projectquay/quay:3.7.6 > $REGISTRY_IMAGES_DIR/quay-3.7.6.tar


    echo "Downloading registry images...done."

}

function downloadRedHatMirrorRegistry
{
    
    echo "Downloading Red Hat mirror registry..."

    curl  https://developers.redhat.com/content-gateway/rest/mirror2/pub/openshift-v4/clients/mirror-registry/${OMG_REDHAT_MIRROR_REGISTRY_VERSION}/mirror-registry.tar.gz > $REGISTRY_IMAGES_DIR/mirror-registry.tar.gz

    echo "Downloading Red Hat mirror registry...done."

}

function packageRegistryImages
{
    echo "Packaging registry images..."
    tar -cf $REGISTRY_IMAGES_DIR.tar $REGISTRY_IMAGES_DIR
    echo "Packaging registry images...done."

}

downloadRegistryImages
downloadRedHatMirrorRegistry
packageRegistryImages
