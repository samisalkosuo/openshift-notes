#!/bin/sh

if [ ! -f "/usr/local/bin/oc" ]; then
    echo "Clients don't seem to be downloaded."
    echo "Download them first."
    exit 1
fi

RHCOS_DIR=$(pwd)/rhcos
OC_IMAGE_DIR_NAME=ocp-images
OCP_IMAGES_DIR=$(pwd)/$OC_IMAGE_DIR_NAME

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

DIST_DIR=dist
#copy binaries and other files to dist-directory
echo "Creating dist-directory..."
mkdir -p $DIST_DIR/bin
cp -r /usr/local/bin/* $DIST_DIR/bin/
mv $RHCOS_DIR $DIST_DIR/
mkdir -p $DIST_DIR/$OC_IMAGE_DIR_NAME
cp $OCP_IMAGES_DIR/*tar $DIST_DIR/$OC_IMAGE_DIR_NAME/
mv registry-images.tar $DIST_DIR/
mv local-repo.tar $DIST_DIR/
cp *.sh *.adoc *.yaml $DIST_DIR/
echo "Creating dist-directory...done."

echo "Copy/move dist-directory to airgapped environment."
echo "Optionally tar dist-directory: tar -cf dist.tar dist/"
