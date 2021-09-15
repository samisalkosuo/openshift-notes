# common functions and supporting functions for other functions

function error
{
    echo $1
    exit 1
}

function createSSHKey
{
  if [ -f ${__ssh_key_file} ]; then
    echo "SSH key already created."
  else
    echo "Creating new SSH key..."
    ssh-keygen -t ${__ssh_type} -N '' -f ${__ssh_key_file}
  fi 
}
