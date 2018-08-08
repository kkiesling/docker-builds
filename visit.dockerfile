FROM  ubuntu:16.04

ENV HOME /root

RUN apt-get -y --force-yes --fix-missing update
RUN apt-get install -y --force-yes \
    software-properties-common wget \
    build-essential python-numpy git cmake vim emacs nano \
    gfortran libblas-dev \
    liblapack-dev libhdf5-dev gfortran python-tables \
    python-matplotlib autoconf libtool python-setuptools cpio \
    libgl1-mesa-glx libgl1-mesa-dev libsm6 libxt6 libglu1-mesa

# build MOAB (in order to use DAGMC-viz)
RUN cd $HOME \
  && mkdir opt \
  && cd opt \
  && mkdir moab \
  && cd moab \
  && git clone https://bitbucket.org/fathomteam/moab \
  && cd moab \
  && git checkout -b Version5.0 origin/Version5.0 \
  && autoreconf -fi \
  && cd .. \
  && mkdir build \
  && cd build \
  && ../moab/configure --enable-shared --enable-optimize --disable-debug --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --prefix=$HOME/opt/moab \
  && make \
  && make install \
  && cd .. \
  && rm -rf build moab

# get visit files (install manually in container)
RUN cd $HOME/opt \
    && wget http://portal.nersc.gov/project/visit/releases/2.13.2/visit2_13_2.linux-x86_64-ubuntu14.tar.gz \
    && wget http://portal.nersc.gov/project/visit/releases/2.13.2/visit-install2_13_2 \
    && echo 1 > input \
    && bash visit-install2_13_2 2.13.2 linux-x86_64-ubuntu14 /usr/local/visit < input

# Add paths to bashrc
RUN    echo 'export PATH=/usr/local/visit/bin:$PATH' >> $HOME/.bashrc \
    && echo 'export LD_LIBRARY_PATH=/usr/local/visit/2.13.2/linux-x86_64/lib/:$LD_LIBRARY_PATH' >> $HOME/.bashrc \
    && echo 'export PYTHONPATH=/usr/local/visit/2.13.2/linux-x86_64/lib/site-packages:$PYTHONPATH' >> $HOME/.bashrc \
    && echo 'export PATH=$HOME/opt/moab/bin/:$PATH' >> $HOME/.bashrc \
    && echo 'export LD_LIBRARY_PATH=$HOME/opt/moab/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc

ENV QT_X11_NO_MITSHM 1

### TO FINISH BUILDING ####
# 1. build docker image
# 2. run container interactively
# 3. install visit in the container:
#       bash visit-install2_13_2 2.13.2 linux-x86_64-ubuntu14 /usr/local/visit
# 4. commit container and exit

### TO RUN VISIT (for Linux based systems) ###
# 1. on local machine, run:
#       xhost +local:root;
# 2. run container again, passing display information (can also mount directories, name the container, etc)
#       docker run -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix/:rw -v /home/kkiesling/Pokeball/Documents/CNERG/:/root/CNERG/ --device=/dev/dri:/dev/dri --name=visit-run visit
# 3. VisIT GUI should be able to be launched from the container
# reference: https://github.com/symerio/visit-docker
