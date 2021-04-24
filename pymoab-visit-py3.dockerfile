FROM  ubuntu:20.04

# set timezone
ENV HOME /root
ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV HOME /root

RUN apt-get -y --force-yes update \
    && apt-get install -y --force-yes \
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
       libtool

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV PATH $HOME/.local/bin:$PATH

# switch to python 3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10; \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10;

# upgrade pip and install python dependencies
RUN python -m pip install --upgrade pip \
    && pip install numpy scipy cython tables matplotlib setuptools future pytest pandas dmsh vtk


# make starting directory
RUN cd $HOME \
  && mkdir opt

# build MOAB
RUN cd $HOME/opt \
    && mkdir moab \
    && cd moab \
    && git clone --depth 1 -b master --single-branch https://bitbucket.org/fathomteam/moab \
    && mkdir build \
    && cd build \
    && cmake ../moab -DCMAKE_C_FLAGS="-fPIC -DPIC" -DCMAKE_CXX_FLAGS="-fPIC -DPIC" -DBUILD_SHARED_LIBS=ON \
       -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-undefined" -DENABLE_MPI=OFF  \
       -DENABLE_HDF5=ON -DHDF5_ROOT=/usr/lib/x86_64-linux-gnu/hdf5/serial \
       -DENABLE_NETCDF=OFF -DENABLE_METIS=OFF -DENABLE_IMESH=OFF -DENABLE_FBIGEOM=OFF \
       -DENABLE_PYMOAB=ON -DBUILD_STATIC_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/opt/moab \
    && make -j 4 \
    && make install \
    && cd $HOME/opt/moab \
    && rm -rf build moab

RUN ls -r $HOME/opt/moab/lib

# set environment variables
ENV PATH $HOME/opt/moab/bin/:$PATH
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV PYTHONPATH $HOME/opt/moab/lib/python3.8/site-packages/:$PYTHONPATH

RUN apt-get -y --force-yes update \
    && apt-get install -y --force-yes wget cpio

RUN pip install ipython

RUN cd $HOME/opt \
    && wget https://github.com/visit-dav/visit/releases/download/v3.2.0/visit3_2_0.linux-x86_64-ubuntu20.tar.gz \
    && wget https://github.com/visit-dav/visit/releases/download/v3.2.0/visit-install3_2_0 \
    && echo 1 > input \
    && bash visit-install3_2_0 3.2.0 linux-x86_64-ubuntu20 /usr/local/visit < input \
    && rm -rf visit3_2_0.linux-x86_64-ubuntu20.tar.gz visit-install3_2_0 input

ENV PATH $HOME/opt/visit3_2_0.linux-x86_64/bin:$PATH
ENV PYTHONPATH /usr/local/visit/3.2.0/linux-x86_64/lib/site-packages/:$PYTHONPATH

