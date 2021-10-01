#this script creates and updates HTPasswd identity provider in OpenShift

set -e

__admin_user_name=cladmin
__admin_password=$(date +%s | sha256sum | base64 | head -c 32 ; echo)

function usage
{
  echo "Create/add/remove users using HTPasswd identity provider."
  echo ""
  echo $"Usage: $0 {create|list|add|changepw|remove}"
  echo ""
  echo "  create                         - Creates HTPasswd secret, adds '${__admin_user_name}' user with random password and sets '${__admin_user_name}' as cluster-admin."
  echo "  list                           - List users in HTPassword identity provider."
  echo "  add <user> <password>          - Add new user with given password."
  echo "  changepw <user> <new_password> - Change password for the given user."
  echo "  remove <user>                  - Remove given user."
  echo ""
  exit 1
}

function error 
{
  echo $1
  exit 1
}

#check that user is logged in
__msg=$(oc whoami)

if [[ $? != 0 ]]; then
  error $__msg
fi

__htpasswd_file=users.htpasswd
__htpasswd_secret_name=htpass-secret
__identity_provider_name=htpasswd_provider

function create
{
  echo "Creating htpasswd file and ${__admin_user_name}-user..."
  htpasswd -c -B -b ${__htpasswd_file} ${__admin_user_name} $__admin_password
  echo "Creating OpenShift secret..."
  oc create secret generic ${__htpasswd_secret_name} --from-file=htpasswd=${__htpasswd_file} -n openshift-config
  echo "Patching cluster OAuth..."

  #get existing identity providers
  local __existing_providers=existing_providers.yaml
  oc get oauth cluster -o json | jq .spec.identityProviders | yq e -P - | sed 's/^/\ \ /g' | sed "s/null//g" > $__existing_providers
  local __htpasswd_patch_file=htpasswd_patch.yaml
  cat > $__htpasswd_patch_file << EOF
spec:
  identityProviders:
  - name: ${__identity_provider_name}
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: ${__htpasswd_secret_name}
EOF
  cat $__existing_providers >> $__htpasswd_patch_file
  echo "Patching HTPasswd Customer Resource..."
  oc patch --type "merge" oauth cluster  -p "$(cat ${__htpasswd_patch_file})"
  echo "Adding ${__admin_user_name} as cluster admin..."
  oc adm policy add-cluster-role-to-user cluster-admin ${__admin_user_name}
  echo "HTPasswd identity provider added."
  echo "User ${__admin_user_name} added as cluster admin."
  echo "Password: $__admin_password"
  echo ""
  echo "Login to cluster:"
  echo "oc login -u ${__admin_user_name}"
}

function retrieveSecret
{
    #echo "Retrieving htpasswd-secret..."
    oc get secret ${__htpasswd_secret_name} -ojsonpath={.data.htpasswd} -n openshift-config | base64 -d > ${__htpasswd_file}
}

function updateSecret
{
    #echo "Updating htpasswd-secret..."
    oc create secret generic ${__htpasswd_secret_name} --from-file=htpasswd=${__htpasswd_file} --dry-run=client -o yaml -n openshift-config | oc replace -f -
}

function adduser
{
    local __user=$1
    if [[ "$__user" == "" ]]; then
      error "User name is missing."
    fi
    local __pwd=$2
    if [[ "$__pwd" == "" ]]; then
      error "Password is missing."
    fi
    echo "Adding/changing user..."
    retrieveSecret
    htpasswd  -B -b ${__htpasswd_file} ${__user} ${__pwd}
    updateSecret
    echo "Adding/changing user...done."
}

function removeuser
{
    local __user=$1
    if [[ "$__user" == "" ]]; then
      error "User name is missing."
    fi
    echo "Removing user..."
    retrieveSecret
    htpasswd  -D ${__htpasswd_file} ${__user}
    updateSecret
    echo "Deleting user..."
    oc delete user ${__user}
    echo "Deleting identity..."
    oc delete identity ${__identity_provider_name}:${__user}
    echo "Removing user...done."
}

function listusers
{
    retrieveSecret
    cat ${__htpasswd_file} |sed "s/:/ /g" |awk '{print $1}'
}

case "$1" in
    create)
        create
        ;;        
    list)
        listusers
        ;;
    add)
        #change password and add user uses same function
        adduser $2 $3
        ;;
    remove)
        removeuser $2
        ;;
    changepw)
        #change password and add user uses same function
        adduser $2 $3
        ;;
    *)
        usage
        ;;
esac
