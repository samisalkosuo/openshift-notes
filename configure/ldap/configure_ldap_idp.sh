#This script configures LDAP identity provider


#modify based on your own environment
#note: this is for insecure LDAP connection
#see documentation about securing LDAP connection
#https://docs.openshift.com/container-platform/4.6/authentication/identity_providers/configuring-ldap-identity-provider.html

set -e
echo "Configuring LDAP identity provider..."

__ldap_name=my-openldap
__ldap_bind_dn=cn=admin,dc=farawaygalaxy,dc=net
__ldap_bind_password=passw0rd
__ldap_server=192.168.47.100
__ldap_server_port=389
__ldap_basedn=dc=farawaygalaxy,dc=net
__ldap_search_attribute=uid
__ldap_mail_attribute=mail
__ldap_name_attribute=cn
__ldap_preferred_username_attribute=uid
__ldap_filter="(objectClass=inetOrgPerson)"

echo "Creating LDAP bind password secret..."
oc create secret generic ${__ldap_name}-secret --from-literal=bindPassword=${__ldap_bind_password} -n openshift-config

__cr_file=${__ldap_name}-cr.yaml
echo "Creating LDAP CR file ${__cr_file}..."
cat > ${__cr_file} << EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ${__ldap_name}-idp 
    mappingMethod: claim 
    type: LDAP
    ldap:
      attributes:
        id: 
        - ${__ldap_search_attribute}
        email: 
        - ${__ldap_mail_attribute}
        name: 
        - ${__ldap_name_attribute}
        preferredUsername: 
        - ${__ldap_preferred_username_attribute}
      bindDN: "${__ldap_bind_dn}" 
      bindPassword: 
        name: ${__ldap_name}-secret
      insecure: true
      url: "ldap://${__ldap_server}:${__ldap_server_port}/${__ldap_basedn}?${__ldap_search_attribute}?sub?${__ldap_filter}" 
EOF

echo "Applying ${__cr_file}..."
oc apply -f ${__cr_file}

echo "Configuring LDAP identity provider...done."
