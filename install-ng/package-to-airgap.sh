#!/bin/sh

if [ ! -f "/usr/local/bin/oc" ]; then
    echo "Clients don't seem to be downloaded."
    echo "Download them first."
    exit 1
fi

RHCOS_DIR=$(pwd)/rhcos
OCP_IMAGES_DIR=$(pwd)/ocp-images

whereis podman |grep "/usr/bin/podman" &> /dev/null
rv=$?

if [ ! $rv -eq 0 ]; then
    echo "Prereqs not installed."
    echo "Install prereqs from repo."
    exit 1
fi


if [ ! -d "$RHCOS_DIR" ]; then
    echo "$RHCOS_DIR does not exist."
    echo "Download RHCOS before packaging them."
    exit 1
fi

if [ ! -f "registry-images.tar" ]; then
    echo "registry-images.tar does not exist."
    echo "Download registry images before packaging them."
    exit 1
fi

if [ ! -f "local-repo.tar" ]; then
    echo "local repo files do not exist."
    echo "Download files from repository before packaging them."
    exit 1

fi

if [ ! -d "$OCP_IMAGES_DIR" ]; then
    echo "ocp-images directory does not exist."
    echo "Mirror OCP images before packaging them."
    exit 1
fi

#copy binaries and other files to dist-directory
echo "Creating dist-directory..."
mkdir -p dist/bin
cp -r /usr/local/bin/* dist/bin/
mv $RHCOS_DIR dist/
mv $OCP_IMAGES_DIR dist/
mv registry-images.tar dist/
mv local-repo.tar dist/
cp *.sh *.adoc *.yaml dist/
echo "Creating dist-directory...done."

echo "Copy/move dist-directory to airgapped environment."
echo "Optionally tar dist-directory: tar -xf dist.tar dist/"
