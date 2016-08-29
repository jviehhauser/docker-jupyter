FROM debian@sha256:32a225e412babcd54c0ea777846183c61003d125278882873fb2bc97f9057c51

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    libav-tools \
    libpq-dev \
    # workaround for pyscopg2 packages / install g++ and make in order to allow installation of xgboost
    gcc \
    g++ \
    make \
    build-essential \
    python-dev \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    libxrender1 \
    inkscape \
    # blas needed for fastFM
    libatlas-base-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# install tini, operating as a process subreaper for jupyter to prevent kernel crashes
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini && \
    echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

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

# Configure ipython kernel to use matplotlib inline backend by default
RUN mkdir -p root/.ipython/profile_default/startup
COPY mplimporthook.py root/.ipython/profile_default/startup/

# Install Python 2 kernel spec globally to avoid permission problems when user id switches at runtime
RUN $CONDA_DIR/bin/python -m ipykernel install

# install nbextensions
RUN pip2 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master
# install nbextensions js/css files
RUN jupyter contrib nbextension install --user
# configure nbextensions
ADD ./notebook.json /root/.jupyter/notebook.json
RUN chmod a+x /root/.jupyter/notebook.json

# Install IJulia packages as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
COPY kernel.json $CONDA_DIR/share/jupyter/kernels/
RUN chmod -R go+rx $CONDA_DIR/share/jupyter

VOLUME /notebooks
VOLUME /misc
VOLUME /data

EXPOSE 8888

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start-notebook.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-notebook.sh
COPY jupyter_notebook_config.py root/.jupyter/
RUN chmod go+rx root/.jupyter
# RUN chown -R root root/.jupyter

