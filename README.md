# ![Jupyter Logo](https://avatars3.githubusercontent.com/u/7388996?v=3&s=200) Dockerized Jupyter Notebook 

![docker automated build](https://img.shields.io/docker/automated/jrottenberg/ffmpeg.svg) ![docker maintained](https://img.shields.io/maintenance/yes/2016.svg) ![docker pulls](https://img.shields.io/docker/pulls/jviehhauser/jupyter-docker.svg)

## Description
[Jupyter](http://blog.jupyter.org/) is a web-based tool supporting exploratory data analysis, which is offered here as a Docker file pre-packaged with miniconda and supporting for execution .

## Usage
You can either start the image directly with Docker, or use the Nomad-Docker-Wrapper if you are running the containers on Nomad.

## What the image offers
* Python 2/3 with a list of base packages pre-installed (cf. requirements.txt)
* Jupyter Notebook 4.2.*
* [tini](https://github.com/krallin/tini) as the container entrypoint and [start-notebook.sh](./start-notebook.sh) as the default command
* Options for password auth, and passwordless `sudo`

## Basic use

The following command starts a container with the Notebook server listening for HTTP connections on port 8888 without authentication configured.

```
docker run -d -p 8888:8888 jviehhauser/docker-jupyter
```

The Docker container executes a [`start-notebook.sh` script](./start-notebook.sh) script by default, which executes the `jupyter notebook`. You can launch the container via:

```
docker run -p 8888:8888 \
  -e PASSWORD="change_me" \
  -e MOUNT_PY2=/misc/miniconda2/bin/python \
  -e JUPYTER_PROCESS_USER_NAME=Seppi \
  -e JUPYTER_PROCESS_USER_ID=501 \
  -e JUPYTER_PROCESS_GROUP_NAME=staff \
  -e JUPYTER_PROCESS_GROUP_ID=20 \
  -v /some/git/project:/notebooks \
  -v /misc:/misc \
  jviehhauser/docker-jupyter
```

## Docker options
The Docker container can be customized via the following arguments: 
* `-e PASSWORD="change_me" - Configures Jupyter Notebook to require the given password. 
* `-e MOUNT_PY2="/misc/miniconda2/bin/python"` - Configures the path for the alternative kernel to be used.
* `-v /some/git/project:/notebooks` - Host mounts the default working directory on the host to preserve work even when the container is destroyed and recreated (e.g., during an upgrade).
* `-v /misc:/misc` - Host mounts a Python distribution to the /misc folder, e.g.: from `/misc/miniconda2/bin/python`.

