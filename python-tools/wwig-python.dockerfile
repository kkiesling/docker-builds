
FROM  ubuntu:20.04

# set timezone
ENV HOME /root
ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir -p /home/cnerg
RUN groupadd -r cnerg &&\
    useradd -r -g cnerg -d /home/cnerg -s /sbin/nologin -c "Docker image user" cnerg

ENV HOME /home/cnerg

RUN apt-get -y --force-yes update \
    && apt-get install -y --force-yes --fix-missing \
    software-properties-common \
    build-essential \
    git \
    cmake \
    gfortran \
    libblas-dev \
    python3-pip \
    liblapack-dev \
    libhdf5-dev \
    autoconf \
    libtool \
    wget \
    cpio \
    libpcre3-dev \
    libgl1-mesa-glx \
    libgl1-mesa-dev \
    libsm-dev \
    libxt6 \
    libglu1-mesa \
    libharfbuzz-dev \
    libice-dev \
    libxext-dev

# switch to python 3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10; \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10;
ENV PATH $HOME/.local/bin:$PATH

# upgrade pip and install python dependencies
RUN python -m pip install --user --upgrade pip
RUN python -m pip install --upgrade pip \
    && pip install \
    numpy \
    scipy \
    cython \
    tables \
    matplotlib \
    setuptools \
    future \
    pytest \
    pandas  \
    nose \
    jinja2 \
    progress \
    meshio

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV PATH $HOME/.local/bin:$PATH
RUN echo "export PATH=$HOME/.local/bin:$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu" >> ~/.bashrc

# make starting directory
RUN cd $HOME \
    && mkdir opt

# build MOAB
RUN cd $HOME/opt \
    && mkdir moab \
    && cd moab \
    && git clone --depth 1 -b Version5.2.0 --single-branch https://bitbucket.org/fathomteam/moab \
    && mkdir build \
    && cd build \
    && cmake ../moab -DCMAKE_C_FLAGS="-fPIC -DPIC" -DCMAKE_CXX_FLAGS="-fPIC -DPIC" -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-undefined" -DENABLE_MPI=OFF  \
    -DENABLE_HDF5=ON -DHDF5_ROOT=/usr/lib/x86_64-linux-gnu/hdf5/serial \
    -DENABLE_NETCDF=OFF -DENABLE_METIS=OFF -DENABLE_IMESH=OFF -DENABLE_FBIGEOM=OFF \
    -DENABLE_PYMOAB=ON -DBUILD_STATIC_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/opt/moab \
    && make -j 8 \
    && make install \
    && cd $HOME/opt/moab \
    && rm -rf build moab

ENV PATH $HOME/opt/moab/bin/:$PATH
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV PYTHONPATH $HOME/opt/moab/lib/python3.8/site-packages/:$PYTHONPATH

RUN echo "export PATH=$HOME/opt/moab/bin/:$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/opt/moab/lib:$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "export PYTHONPATH=$HOME/opt/moab/lib/python3.8/site-packages/:$PYTHONPATH" >> ~/.bashrc

# install Visit
RUN cd $HOME/opt \
    && wget https://github.com/visit-dav/visit/releases/download/v3.2.1/visit3_2_1.linux-x86_64-ubuntu20.tar.gz \
    && wget https://github.com/visit-dav/visit/releases/download/v3.2.1/visit-install3_2_1 \
    && echo 1 > input \
    && bash visit-install3_2_1 3.2.1 linux-x86_64-ubuntu20 /usr/local/visit < input \
    && rm -rf visit3_2_1.linux-x86_64-ubuntu20.tar.gz visit-install3_2_1

ENV PATH /usr/local/visit/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/visit/3.2.1/linux-x86_64/lib/:$LD_LIBRARY_PATH
ENV PYTHONPATH /usr/local/visit/3.2.1/linux-x86_64/lib/site-packages:$PYTHONPATH

RUN echo "export PATH=/usr/local/visit/bin:$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=/usr/local/visit/3.2.1/linux-x86_64/lib/:$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "export PYTHONPATH=/usr/local/visit/3.2.1/linux-x86_64/lib/site-packages:$PYTHONPATH" >> ~/.bashrc

# Install PyNE
RUN cd $HOME/opt \
    && git clone --depth 1 --branch develop --single-branch https://github.com/pyne/pyne.git \
    && cd pyne \
    && python setup.py install --user \
    --moab $HOME/opt/moab \
    --clean

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH
RUN echo "export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH" >> ~/.bashrc

RUN cd $HOME && nuc_data_make

# download wwinp expand tool
RUN cd $HOME/opt \
    && git clone https://gist.github.com/a7ddb48f80fbd39449211776f51c7722.git expand_wwinp
ENV PATH $HOME/opt/expand_wwinp/:$PATH
RUN echo "export PATH=$HOME/opt/expand_wwinp/:$PATH" >> ~/.bashrc

# install isogeom
RUN cd $HOME/opt \
    && git clone --depth 1 -b mesh-refine --single-branch https://github.com/kkiesling/IsogeomGenerator.git \
    && cd IsogeomGenerator \
    && pip install . --user

ENV PYTHONPATH $HOME/.local/lib/python3.8/site-packages/IsogeomGenerator:$PYTHONPATH
RUN echo "export PYTHONPATH=$HOME/.local/lib/python3.8/site-packages/IsogeomGenerator:$PYTHONPATH" >> ~/.bashrc

RUN pip install ipython PySide2

ENV PYTHONPATH $HOME/.local/lib/python3.8/site-packages/:$PYTHONPATH
RUN echo "export PYTHONPATH=$HOME/.local/lib/python3.8/site-packages/:$PYTHONPATH" >> ~/.bashrc

ENV PYTHONPATH $HOME/.local/lib/python3.8/dist-packages/:$PYTHONPATH
RUN echo "export PYTHONPATH=$HOME/.local/lib/python3.8/dist-packages/:$PYTHONPATH" >> ~/.bashrc

# change ownership of home
RUN chmod -R a+rwX  $HOME
