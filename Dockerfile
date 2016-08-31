FROM debian@sha256:32a225e412babcd54c0ea777846183c61003d125278882873fb2bc97f9057c51

USER root

# configure environment
RUN mkdir /jupyter
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV HOME /jupyter

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive

# installing sudo

RUN apt-get update && apt-get install -yq --no-install-recommends \
    sudo \
    wget \
    bzip2 \
    unzip \
    locales \
    make \
    build-essential \
    python-dev \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    && apt-get clean all && \
    rm -rf /var/lib/apt/lists/*

# packages as a pre-requisite for miniconda2 setup
RUN apt-get update && apt-get install -yq --no-install-recommends \
    libpq-dev \
    gcc \
    g++ \
    # blas needed for fastFM
    libatlas-base-dev \
    && apt-get clean all && \
    rm -rf /var/lib/apt/lists/*

# set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Add Tini. Tini operates as a process subreaper for jupyter. This prevents
# kernel crashes.
ENV TINI_VERSION v0.10.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini
ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Install (mini)conda
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet http://repo.continuum.io/miniconda/Miniconda2-4.1.11-Linux-x86_64.sh && \
    /bin/bash Miniconda2-4.1.11-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda2-4.1.11-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --quiet --yes conda==4.1.11 && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    conda clean -tipsy

# install setuptools
RUN conda install -f pip setuptools

RUN conda install --quiet --yes \
    'ipython=4.2*' \
    'ipywidgets=5.1*' \
    'pandas=0.18*' \
    'numexpr=2.5*' \
    'matplotlib=1.5*' \
    'scipy=0.17*' \
    'sympy=1.0*' \
    'cython=0.23*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.23*' \
    'bokeh=0.11*' \
    'h5py=2.5*' \
    'pyzmq' && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

# Add shortcuts to distinguish pip for python2 and python3 envs
RUN ln -s $CONDA_DIR/envs/python3/bin/pip $CONDA_DIR/bin/pip3 && \
    ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip2

# Install requirements
ADD requirements.txt requirements.txt
RUN pip2 --no-cache-dir install -r requirements.txt

# install tensorflow
ENV TF_BINARY_URL https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.10.0rc0-cp27-none-linux_x86_64.whl
RUN pip2 install --ignore-installed --upgrade $TF_BINARY_URL

# Install Python 2 kernel spec globally to avoid permission problems when user id switches at runtime
RUN $CONDA_DIR/bin/python -m ipykernel install

# install nbextensions
RUN pip2 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master
RUN jupyter contrib nbextension install --user

# define volumes
VOLUME /notebooks
VOLUME /misc
VOLUME /data

EXPOSE 8888

# Configure container startup
ENTRYPOINT ["usr/local/bin/tini", "--"]
CMD ["start-notebook.sh"]

# set ipython profiles
RUN mkdir -p $HOME/.ipython/profile_default/startup
# configures ipython kernel to use matplotlib inline by default
COPY mplimporthook.py $HOME/.ipython/profile_default/startup/
COPY conf.templates conf.templates
COPY jupyter_notebook_config.py $HOME/.jupyter/
COPY notebook.json $HOME/.jupyter/nbconfig/

# add startup script
COPY start-notebook.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-notebook.sh
