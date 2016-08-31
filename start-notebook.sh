#!/bin/bash

set -e

#### Jupyter configurations
echo "> Adding Jupyter configuration"
function config_add_kernel_json {
    local conf_name=$1
    local kernel_path=$2
    local envs_to_replace=$3
    mkdir $kernel_path

    echo "Creating and copying $conf_name"
    envsubst $envs_to_replace < conf.templates/$conf_name.template > $kernel_path/$conf_name
}

if [ -z ${MOUNT_PY2+x} ]
then
    echo "Python2 mount path is not set"
else
    echo "Python2 mount path is set to '$MOUNT_PY2'"
    config_add_kernel_json kernel.json $CONDA_DIR/share/jupyter/kernels/isilon_python2/
fi

echo "> Specify theme"
if [ -z ${USE_THEME+x} ]
then
    echo "Not using a theme"
    jt -r
else
    echo "Using a a standard theme"
    jt -fs 8 -nfs 8 -tfs 8 -nf sourcesans -f roboto -T -N
fi

#### User handling
function create_user {
    # add JUPYTER group if not exists
    if getent group $JUPYTER_PROCESS_GROUP_NAME; then
      echo "Group $JUPYTER_PROCESS_GROUP_NAME already exists"
    else
      echo "Group $JUPYTER_PROCESS_GROUP_NAME does not exist, creating it with gid=$JUPYTER_PROCESS_GROUP_ID"
      addgroup --force-badname -gid $JUPYTER_PROCESS_GROUP_ID $JUPYTER_PROCESS_GROUP_NAME
    fi

    # add JUPYTER user if not exists
    if id -u $JUPYTER_PROCESS_USER_NAME 2>/dev/null; then
      echo "User $JUPYTER_PROCESS_USER_NAME already exists"
    else
      echo "User $JUPYTER_PROCESS_USER_NAME does not exist, creating it with uid=$JUPYTER_PROCESS_USER_ID"
      adduser --force-badname $JUPYTER_PROCESS_USER_NAME --uid $JUPYTER_PROCESS_USER_ID --gecos "" \
      --ingroup $JUPYTER_PROCESS_GROUP_NAME --disabled-login --disabled-password \
      --home /jupyter
    fi

    chown -R $JUPYTER_PROCESS_USER_NAME:$JUPYTER_PROCESS_GROUP_NAME /jupyter
}

echo "> Creating user and firing up Jupyter notebook ..."
if [ -z ${JUPYTER_PROCESS_USER_NAME+x} ]
then
    echo "WARNING: You will operate the notebook as a user 'root'"
    jupyter notebook $*
else
    echo "INFO: User will be changed according to your input"
    create_user
    sudo -u $JUPYTER_PROCESS_USER_NAME $CONDA_DIR/bin/jupyter notebook $*
fi



