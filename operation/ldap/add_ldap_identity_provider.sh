#add identity provider to oauth cluster


#modify based on your own environment
#note: this is for insecure LDAP connection
#see documentation about securing LDAP connection
#https://docs.openshift.com/container-platform/4.6/authentication/identity_providers/configuring-ldap-identity-provider.html

echo "Adding LDAP identity provider..."

set -e 


#set LDAP parameters 
__ldap_name=openldap-demo
__ldap_bind_dn=cn=admin,dc=farawaygalaxy,dc=net
__ldap_bind_password=passw0rd
__ldap_server=192.168.47.99
__ldap_server_port=389
__ldap_insecure=true
__ldap_basedn=dc=farawaygalaxy,dc=net
__ldap_search_attribute=uid
__ldap_name_attribute=cn
__ldap_preferred_username_attribute=uid
__ldap_filter="(objectClass=inetOrgPerson)"


echo "Creating LDAP bind password secret..."
oc create secret generic ${__ldap_name}-secret --from-literal=bindPassword=${__ldap_bind_password} -n openshift-config

#TODO check if provider already exists
#local existingProvider=$(oc get oauth cluster -o json | jq '.spec.identityProviders[] |  select( .name == "provider name" )')

#get existing identity providers
__existing_providers=existing_providers.yaml
oc get oauth cluster -o json | jq .spec.identityProviders | yq e -P - | sed 's/^/\ \ /g' | sed "s/null//g" > $__existing_providers

__ldap_patch_file=ldap_patch.yaml
echo "Creating LDAP identity provider patch YAML..."
cat > ${__ldap_patch_file} << EOF
spec:
  identityProviders:
  - name: ${__ldap_name} 
    mappingMethod: claim 
    type: LDAP
    ldap:
      attributes:
        id: 
        - ${__ldap_search_attribute}
        name: 
        - ${__ldap_name_attribute}
        preferredUsername: 
        - ${__ldap_preferred_username_attribute}
      bindDN: "${__ldap_bind_dn}" 
      bindPassword: 
        name: ${__ldap_name}-secret
      insecure: ${__ldap_insecure}
      url: "ldap://${__ldap_server}:${__ldap_server_port}/${__ldap_basedn}?${__ldap_search_attribute}?sub?${__ldap_filter}" 
EOF

cat $__existing_providers >> ${__ldap_patch_file}

echo "Patching cluster OAuth..."
oc patch --type "merge" oauth cluster  -p "$(cat ${__ldap_patch_file})"

echo "Adding LDAP identity provider...done."
