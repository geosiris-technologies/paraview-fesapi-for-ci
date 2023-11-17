
# Copyright 2023 Geosiris
# SPDX-License-Identifier: Apache-2.0


# To build the image from a local source checkout:
# $ docker buildx build -t paraview-fesapi-for-ci -f paraview-fesapi-for-ci.Dockerfile .
# and run bash:
# $ docker exec -it paraview-fesapi-for-ci bash

FROM ubuntu:22.04

LABEL maintainer="lionel.untereiner@geosiris.com"
LABEL org.opencontainers.image.ref.name=ubuntu
LABEL org.opencontainers.image.version=20.04
LABEL org.opencontainers.image.source="https://github.com/geosiris-technologies/paraview-fesapi-for-ci"

RUN export DEBIAN_FRONTEND=noninteractive; \
    export DEBCONF_NONINTERACTIVE_SEEN=true; \
    echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections; \
    echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections; \
    apt-get update -qqy && \
    apt-get install -qqy --no-install-recommends tzdata keyboard-configuration && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#paraview and fesapi dependencies
RUN apt-get update -y \
 && apt-get install -y git cmake build-essential libgl1-mesa-dev libxt-dev \
        libqt5x11extras5-dev libqt5help5 qttools5-dev qtxmlpatterns5-dev-tools libqt5svg5-dev \
        python3-dev python3-numpy libtbb-dev ninja-build qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
        libminizip-dev libboost-dev openssl libhdf5-dev zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG BUILD_TYPE=Release

#
#Fesapi
ARG FESAPI_VERSION=origin/dev
ARG FESAPI_DIR=/opt/fesapi

RUN mkdir -p $FESAPI_DIR \
 && cd $FESAPI_DIR \
 && git clone https://github.com/F2I-Consulting/fesapi.git src \
 && cd src \
 && git checkout $FESAPI_VERSION \ 
 && cd ../ \
 && mkdir build \
 && cd ./build \
 && cmake -GNinja \
            -DCMAKE_INSTALL_PREFIX=$FESAPI_DIR \
            -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=TRUE \
            -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
            -DWITH_EXAMPLE:BOOL=OFF \
            -DWITH_DOTNET_WRAPPING:BOOL=OFF \
            -DWITH_JAVA_WRAPPING:BOOL=OFF \
            -DWITH_PYTHON_WRAPPING:BOOL=OFF \
            -DWITH_RESQML2_2:BOOL=OFF \
            -DWITH_TEST:BOOL=OFF \
            ../src \
 && cmake --build . --target install \
 && cd ../ \
 && rm -rf src build


#
#Paraview
ARG PARAVIEW_VERSION=v5.11.2
ARG PARAVIEW_DIR=/opt/paraview

RUN mkdir -p $PARAVIEW_DIR \
 && cd $PARAVIEW_DIR \
 && git clone https://github.com/Kitware/paraview.git src \
 && cd src \
 && git checkout $PARAVIEW_VERSION \
 && git submodule update --init --recursive \
 && cd ../ \
 && mkdir build \
 && cd ./build \
 && cmake -GNinja \
            -DCMAKE_INSTALL_PREFIX=$PARAVIEW_DIR \
            -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
            -DPARAVIEW_USE_PYTHON=ON \
            -DPARAVIEW_USE_MPI=OFF \
            -DVTK_SMP_IMPLEMENTATION_TYPE=TBB \
            -DVTK_MODULE_USE_EXTERNAL_VTK_hdf5:BOOL=ON \
            -DVTK_MODULE_USE_EXTERNAL_VTK_zlib:BOOL=ON \
            ../src \
 && cmake --build . --target install \
 && cd ../ \
 && rm -rf src build