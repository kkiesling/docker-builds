FROM ubuntu:20.04

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
       python3-pip \
       liblapack-dev \
       libhdf5-dev \
       libtool


RUN cd $HOME \
    && mkdir advantg

RUN cd $HOME \
    && mkdir mcnp

COPY advantg-3.0.3-release/ $HOME/advantg/

COPY mcnp5 $HOME/mcnp
ENV PATH $HOME/advantg-exe/bin:$PATH

RUN chmod -R a+rwX  $HOME

# USER cnerg
