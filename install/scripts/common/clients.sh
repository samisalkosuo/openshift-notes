#download required clients



function downloadOpenShiftClient
{
    local __file=$1
    echo "Downloading ${__file}..."
    local __dlurl=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION
    curl $__dlurl/${__file} > ${__file}

    echo "Extracting ${__file} to /usr/local/bin/..."
    tar  -C /usr/local/bin/ -xf ${__file}
    rm -f  ${__file}
    echo "Downloading ${__file}...done."
}

function downloadGrpcurl
{
    echo "Downloading grpcurl..."
    local __client_filename=grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz
    curl -L https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/${__client_filename} > ${__client_filename}
    echo "Extracting grpcurl to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f ${__client_filename}
    echo "Downloading grpcurl...done."
}

function downloadCloudctl
{
    echo "Downloading cloudctl..."
    local __client_filename=cloudctl-linux-amd64.tar.gz
    curl -L https://github.com/IBM/cloud-pak-cli/releases/download/v${CLOUDCTL_VERSION}/${__client_filename} > ${__client_filename}
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f /usr/local/bin/cloudctl
    mv /usr/local/bin/cloudctl* /usr/local/bin/cloudctl
    rm -f ${__client_filename}
    echo "Downloading cloudctl...done."
}

function downloadKubeterminal
{
    echo "Downloading kubeterminal.bin..."
    podman create -it --name kubeterminal docker.io/kazhar/kubeterminal bash
    podman cp kubeterminal:/kubeterminal kubeterminal.bin
    podman rm -fv kubeterminal
    podman rmi kazhar/kubeterminal
    echo "Copying kubeterminal.bin to /usr/local/bin/..."
    mv kubeterminal.bin /usr/local/bin/
    echo "Downloading kubeterminal.bin...done."
}

function downloadCoreDNS
{
    #https://github.com/coredns/coredns/releases/download/v1.8.4/coredns_1.8.4_linux_amd64.tgz
    echo "Downloading coredns..."
    local __client_filename=coredns_${COREDNS_VERSION}_linux_amd64.tgz
    curl -L https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/${__client_filename} > ${__client_filename}
    echo "Extracting coredns to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f ${__client_filename}
    echo "Downloading coredns...done."
}

function downloadGobetween
{
    echo "Downloading gobetween..."
    #https://github.com/yyyar/gobetween/releases/download/0.8.0/gobetween_0.8.0_linux_amd64.tar.gz
    local __client_filename=gobetween_${GOBETWEEN_VERSION}_linux_amd64.tar.gz
    curl -L https://github.com/yyyar/gobetween/releases/download/${GOBETWEEN_VERSION}/${__client_filename} > ${__client_filename}
    echo "Extracting gobetween to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f ${__client_filename}
    echo "Downloading gobetween...done."
}

function downloadGovc
{
    #https://github.com/vmware/govmomi/releases/download/v0.26.1/govc_Linux_x86_64.tar.gz
    echo "Downloading govc..."    
    local __client_filename=govc_Linux_x86_64.tar.gz
    curl -L https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/${__client_filename} > ${__client_filename}
    echo "Extracting govc to /usr/local/bin/"
    tar  -C /usr/local/bin/ -xf ${__client_filename}
    rm -f ${__client_filename}
    echo "Downloading govc...done."
    
}

function downloadYQ
{
    #https://github.com/mikefarah/yq
    echo "Downloading yq..."    
    local __client_filename=yq
    curl -L https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 > ${__client_filename}
    chmod 755 yq
    mv yq /usr/local/bin
    echo "Downloading yq...done."

}

function downloadClients
{
  echo "Downloading clients..."
  if [ ! -f "/usr/local/bin/oc" ]; then

    downloadOpenShiftClient openshift-client-linux.tar.gz

    downloadOpenShiftClient openshift-install-linux.tar.gz

    downloadOpenShiftClient opm-linux.tar.gz

    downloadGrpcurl

    downloadCloudctl

    downloadCoreDNS
    
    downloadGobetween

    downloadGovc

    downloadYQ
    
    downloadKubeterminal

  else
    echo "Clients seem to be already downloaded."
    echo "delete /usr/local/bin/oc to download all clients again."
  fi
  echo "Downloading clients...done."

}

