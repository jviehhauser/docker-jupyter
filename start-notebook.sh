#!/bin/bash

set -e

echo "> Adding Jupyter configuration"
function config_add_kernel_json {
  local conf_name=$1
  local kernel_path=$2
  local envs_to_replace=$3
  mkdir $kernel_path

  echo "Creating and copying $conf_name"
  envsubst $envs_to_replace < conf.templates/$conf_name.template > $kernel_path/$conf_name
}

if [ -z ${MOUNT_PY2+x} ] #note the lack of a $ sigil
then
    echo "Python2 mount path is not set"
else
    echo "Python2 mount path is set to '$MOUNT_PY2'"
    config_add_kernel_json kernel.json $CONDA_DIR/share/jupyter/kernels/isilon_python2/
fi

echo "> Firing up Jupyter notebook"

jupyter notebook $*
