function downloadClients
{
  echo "Downloading clients..."
  if [ ! -f "/usr/local/bin/oc" ]; then
    local __client_filename=openshift-client-linux.tar.gz

    local dlurl=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION
    echo "Downloading oc..."
    curl $dlurl/${__client_filename} > ${__client_filename}

    echo "Copying oc and kubectl to /usr/local/bin/..."
    tar  -C /usr/local/bin/ -xf ${__client_filename}

    echo "Downloading openshift-install..."
    __client_filename=openshift-install-linux.tar.gz
    curl $dlurl/${__client_filename} > ${__client_filename}
    echo "Copying openshift-install to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}

    echo "Downloading opm..."
    __client_filename=opm-linux.tar.gz
    curl $dlurl/${__client_filename} > ${__client_filename}
    echo "Copying opm to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}

    echo "Downloading grpcurl..."
    __client_filename=grpcurl_1.8.2_linux_x86_64.tar.gz
    curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.8.2/${__client_filename} > ${__client_filename}
    echo "Copying grpcurl to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}

    echo "Downloading kubeterminal.bin..."
    podman create -it --name kubeterminal docker.io/kazhar/kubeterminal bash
    podman cp kubeterminal:/kubeterminal kubeterminal.bin
    podman rm -fv kubeterminal
    podman rmi kazhar/kubeterminal
    echo "Copying kubeterminal.bin to /usr/local/bin/..."
    mv kubeterminal.bin /usr/local/bin/
  else
    echo "oc client already exists."
    echo "delete /usr/local/bin/oc to download again."
  fi
  echo "Downloading clients...done."

}

function downloadFile
{
#naming conventions
#kernel: rhcos-<version>-live-kernel-<architecture>
#initramfs: rhcos-<version>-live-initramfs.<architecture>.img
#rootfs: rhcos-<version>-live-rootfs.<architecture>.img

   local dlurl=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${__release}/${__version}
   local dir=/var/www/html/rhcos
  if [ -f ${dir}/$1 ]; then
    echo "$1 already downloaded."
  else
    wget --directory-prefix=${dir} ${dlurl}/$1
  fi 
}


function downloadRHCOSBinaries
{
    local __release=$OCP_RHCOS_MAJOR_RELEASE
    local __version=$OCP_RHCOS_VERSION
    local __architecture=x86_64

    echo "Downloading RHCOS ${__version} kernel..."
    downloadFile rhcos-${__version}-${__architecture}-live-kernel-${__architecture}

    echo "Downloading RHCOS ${__version} initramfs..."
    downloadFile rhcos-${__version}-${__architecture}-live-initramfs.${__architecture}.img

    echo "Downloading RHCOS ${__version} rootfs..."
    downloadFile rhcos-${__version}-${__architecture}-live-rootfs.${__architecture}.img

}
