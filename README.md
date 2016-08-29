# ![Jupyter Logo](http://blog.jupyter.org/content/images/2015/02/jupyter-sq-text.png) Dockerized Jupyter Notebook 

## Description

[Jupyter](http://blog.jupyter.org/) is a web-based tool supporting exploratory data analysis, which is offered here as a Docker file pre-packaged with miniconda and supporting for execution .

## Usage

You can either start the image directly with Docker, or use the Nomad-Docker-Wrapper if you are running the containers on Nomad.

## Python Packages

![docker pulls](https://img.shields.io/docker/pulls/jupyter/base-notebook.svg) ![docker stars](https://img.shields.io/docker/stars/jupyter/base-notebook.svg)

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

The Docker container executes a [`start-notebook.sh` script](./start-notebook.sh) script by default, which executes the `jupyter notebook`. You can pass [Jupyter CLI options](http://jupyter.readthedocs.org/en/latest/config.html#command-line-arguments) through the `start-notebook.sh` script when launching the container, e.g.:

```
docker run -d -p 8888:8888 jviehhauser/docker-jupyter start-notebook.sh --NotebookApp.password='sha1:74ba40f8a388:c913541b7ee99d15d5ed31d4226bf7838f83a50e' --NotebookApp.base_url=/some/path
```

## Docker options

The Docker container can be customized via the following arguments: 
* `-e PASSWORD="SHA1_PASS"` - Configures Jupyter Notebook to require the given pre-hashed password. You can generate it via `ipython -c 'from notebook.auth import passwd; print(passwd())'`.
* `-v /some/git/project:/notebooks` - Host mounts the default working directory on the host to preserve work even when the container is destroyed and recreated (e.g., during an upgrade).
