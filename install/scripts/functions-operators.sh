function olm_printOperatorIndexImage
{
    echo "Operator index image:"
    echo ${__operator_index_image}
}

function olm_setRegistryAuthentication
{
    #setup authentication to redhat registry using pull-secret
    REGISTRY_AUTH_FILE=$OCP_PULL_SECRET_FILE
}

function olm_listOperators
{
    echo "Operators:"
    olm_setRegistryAuthentication
    #list packages
    podman run -p50051:50051 -d --name index-image registry.redhat.io/redhat/redhat-operator-index:v4.6 > /dev/null
    sleep 2
    grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out
    podman stop index-image &> /dev/null
    podman rm index-image &> /dev/null
    cat packages.out |grep \"name\": | sed s/\"//g | sed "s/  name: //g"

}
