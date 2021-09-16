##this scripts pulls and saves  NFS client provisioner image
#see https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

set -e

echo "Cloning https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner..."
git clone https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

echo ""
echo "Getting NFS client provisioner image name..."
__image_name=$(cat nfs-subdir-external-provisioner/deploy/deployment.yaml  |grep image: |awk '{print $2}')
__my_image_name=nfs-client-provisioner
__my_image_fullname=${__my_image_name}:latest
__image_file_name=${__my_image_name}.tar

echo ""
echo "Pulling ${__image_name}..."
podman pull ${__image_name} 

echo ""
echo "Tagging ${__image_name} to ${__my_image_fullname}..."
podman tag ${__image_name} ${__my_image_fullname}

echo ""
echo "Packaging image and deployment files..."
__pkg_dir=nfs-client-provisioner
__pkg_file=nfs-client-provisioner-files.tar
mkdir ${__pkg_dir}
podman save > ${__pkg_dir}/${__image_file_name} ${__my_image_fullname}
cp -R nfs-subdir-external-provisioner/deploy/* ${__pkg_dir}/
tar -cf ${__pkg_file} ${__pkg_dir}
echo "Packaging done." 
echo "File: ${__pkg_file}"
