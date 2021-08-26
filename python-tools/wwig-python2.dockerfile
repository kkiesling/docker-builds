FROM  ubuntu:20.04

# set timezone

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir -p /home/cnerg
RUN groupadd -r cnerg &&\
    useradd -r -g cnerg -d /home/cnerg -s /sbin/nologin -c "Docker image user" cnerg

ENV HOME /home/cnerg

RUN apt-get -y --force-yes update \
    && apt-get install -y --force-yes \
        software-properties-common \
        build-essential \
        git \
        cmake \
        gfortran \
        libblas-dev \
        liblapack-dev \
        libhdf5-dev \
        autoconf \
        libtool \
        wget \
        cpio \
        libpcre3-dev \
        libgl1-mesa-glx \
        libgl1-mesa-dev \
        libsm6 \
        libxt6 \
        libglu1-mesa \
        libharfbuzz-dev

# install python 2
RUN apt-add-repository universe \
    && apt-get -y --force-yes update \
    && apt-get install -y --force-yes python2-dev

# set python2 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 2 \
    && echo 1 | update-alternatives --config python


RUN echo `python --version`

RUN apt-get -y --force-yes update \
    && apt-get install -y --force-yes apt-utils curl \
    && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
    && python2 get-pip.py

ENV PATH $HOME/.local/bin:$PATH

# upgrade pip and install python dependencies
RUN python -m pip install --user --upgrade pip

RUN pip install \
    numpy \
    scipy \
    cython \
    tables \
    matplotlib \
    setuptools \
    future \
    pytest \
    pandas  \
    meshio

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
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
ENV PYTHONPATH $HOME/opt/moab/lib/python2.7/site-packages/:$PYTHONPATH

RUN echo "export PATH=$HOME/opt/moab/bin/:$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/opt/moab/lib:$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "export PYTHONPATH=$HOME/opt/moab/lib/python2.7/site-packages/:$PYTHONPATH" >> ~/.bashrc

# install Visit
RUN cd $HOME/opt \
    && wget https://github.com/visit-dav/visit/releases/download/v3.1.2/visit3_1_2.linux-x86_64-ubuntu20.tar.gz \
    && wget https://github.com/visit-dav/visit/releases/download/v3.1.2/visit-install3_1_2 \
    && echo 1 > input \
    && bash visit-install3_1_2 3.1.2 linux-x86_64-ubuntu20 /usr/local/visit < input \
    && rm -rf visit3_1_2.linux-x86_64-ubuntu20.tar.gz visit-install3_1_2 input

# add visit to end of paths
ENV PATH $PATH:/usr/local/visit/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/visit/3.1.2/linux-x86_64/lib/
ENV PYTHONPATH $PYTHONPATH:/usr/local/visit/3.1.2/linux-x86_64/lib/site-packages

RUN echo "export PATH=$PATH:/usr/local/visit/bin" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/visit/3.1.2/linux-x86_64/lib/" >> ~/.bashrc \
    && echo "export PYTHONPATH=$PYTHONPATH:/usr/local/visit/3.1.2/linux-x86_64/lib/site-packages" >> ~/.bashrc

# install isogeom
RUN cd $HOME/opt \
    && git clone --depth 1 -b main --single-branch https://github.com/CNERG/IsogeomGenerator.git \
    && cd IsogeomGenerator \
    && pip install . --user

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH
RUN echo "export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH" >> ~/.bashrc

ENV PYTHONPATH $HOME/.local/lib/python2.7/site-packages/IsogeomGenerator:$PYTHONPATH
RUN echo "export PYTHONPATH=$HOME/.local/lib/python2.7/site-packages/IsogeomGenerator:$PYTHONPATH" >> ~/.bashrc

ENV PYTHONPATH /usr/local/lib/python2.7/dist-packages/:$PYTHONPATH
RUN echo "export PYTHONPATH=/usr/local/lib/python2.7/dist-packages/:$PYTHONPATH" >> ~/.bashrc

RUN pip install vtk ipython

# change ownership of home
RUN chmod -R a+rwX  $HOME
