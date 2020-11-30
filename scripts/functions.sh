#omg.sh functions 

function usageEnv
{
  echo "$1 env variable missing."
  echo "edit and source config.sh."
  exit 1
}

function check_role
{
  local rv=1
  #check whether or not operation is permitted in server
  local roles=$1
  for role in $roles
  do
    if [[ "$role" == "${OCP_OMG_SERVER_ROLE}" ]]; then
      #echo "Operation is allowed in ${OCP_OMG_SERVER_ROLE}."
      rv="${rv}0"
    fi
  done

  set +e
  #if rv does not include 0, then operation is not allowed
  echo $rv |grep 0 &> /dev/null
  if [[ $? != 0 ]]; then
    echo "ERROR: Operation not allowed in current OCP_OMG_SERVER_ROLE=${OCP_OMG_SERVER_ROLE}."
    exit 3
  fi
  set -e
}

function prereq_install
{
  if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
    echo "enabling Extra Packages for Enterprise Linux..."
    #see https://fedoraproject.org/wiki/EPEL
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    __enable_epel_testing="--enablerepo=epel-testing"
  fi
  echo "installing packages...."
  yum -y ${__enable_epel_testing} install $__packages 

  if [[ "$OCP_OMG_SERVER_ROLE" == "jump" ]]; then
    echo "creating alpine-base image..."
    podman build -t alpine-base ./install/alpine-base
    echo "alpine-base image created"
  fi
  echo "prereq-install done."
}

function downloadKubeTerminal
{
  #downloads kubeterminal to current directory
  podman create -it --name kubeterminal kazhar/kubeterminal bash
  podman cp kubeterminal:/kubeterminal kubeterminal.bin
  podman rm -fv kubeterminal
  podman rmi kazhar/kubeterminal
}
