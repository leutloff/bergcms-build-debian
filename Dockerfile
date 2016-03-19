# Debian 8.0 Jessie, 64-Bit
# Jessie: (libboost-dev 1.55.02), gcc 4.9.2, (cmake 3.0)
FROM debian:jessie
ARG CMAKE_ARCH=x86_64

MAINTAINER Christian Leutloff <leutloff@sundancer.oche.de>

# Install the build environment
# Python is required by ctemplate, only
# Curl with ca-certificates is used to download CMake 3.5
RUN apt-get update && apt-get install --no-install-recommends -y \
    gcc \
    g++ \
    python \
    perl \
    libtool \
    autoconf \
    automake \
    make \
    patch \
    curl \
    ca-certificates \
    file \
    less \
    git \
    bzip2 \
    xz-utils \
    libc6-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libssl-dev \
    libicu-dev \
 && rm -rf /var/lib/apt/lists/*
#     libboost-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-iostreams-dev \
#       libboost-log-dev libboost-program-options-dev libboost-regex-dev libboost-signals-dev libboost-system-dev \
#       libboost-test-dev libboost-thread-dev


# Install CMake 3.5, export OPTDIR=/opt, export CMAKEDIR=/opt/cmake-3.5, get shellscript installer, execute the downloaded file, add link from /usr/local/bin
ENV OPTDIR /opt
ENV CMAKEDIR /opt/cmake-3.5
RUN mkdir -p "$OPTDIR" "$CMAKEDIR" && (cd "$OPTDIR" \
    && curl -LO https://cmake.org/files/v3.5/cmake-3.5.0-Linux-$CMAKE_ARCH.sh \
    && /bin/sh ./cmake-*-Linux-$CMAKE_ARCH.sh --prefix=$CMAKEDIR --skip-license \
    && ln -sf $CMAKEDIR/bin/cmake /usr/local/bin/cmake \
    && ln -sf $CMAKEDIR/bin/ccmake /usr/local/bin/ccmake \
    && ln -sf $CMAKEDIR/bin/cpack /usr/local/bin/cpack \
    && ln -sf $CMAKEDIR/bin/ctest /usr/local/bin/ctest \
    && cd -)
#RUN mkdir -p "$OPTDIR" "$CMAKEDIR" && (cd "$OPTDIR" && curl -sLO https://cmake.org/files/v3.5/cmake-3.5.0-Linux-i386.sh && /bin/sh ./cmake-*-Linux-i386.sh --prefix=$CMAKEDIR --skip-license && ln -sf $CMAKEDIR/bin/cmake /usr/local/bin/cmake && cd -)
RUN cmake --version

RUN find /usr/lib -name 'libicu*.so.*' -print

ARG boost_version=1.58.0
ARG boost_dir=boost_1_58_0
ENV boost_version ${boost_version}
RUN curl -LO https://downloads.sourceforge.net/project/boost/boost/${boost_version}/${boost_dir}.tar.bz2 \
    && tar --bzip2 -xf ${boost_dir}.tar.bz2 \
    && rm ${boost_dir}.tar.bz2 \
    && cd ${boost_dir} \
    && ./bootstrap.sh --with-libraries=atomic,chrono,date_time,filesystem,iostreams,log,program_options,regex,signals,system,test,thread \
    && ./b2 -j 4 link=shared runtime-link=shared install -d0 --prefix=/usr \
    && cd .. && rm -rf ${boost_dir} && ldconfig
RUN find /usr/lib -name 'libboost*.so.*' -print
# ./bootstrap.sh --help
# ./bootstrap.sh --show-libraries
# ./b2 --help
# In boost 1.60 leads boost/iostreams/stream.hpp to:
#pragma message: NOTE: Use of this header (template_arity_spec.hpp) is deprecated
# Fix: https://github.com/boostorg/iostreams/pull/24

ENV BASEDIR /usr/src
ENV BGDIR /usr/src/bergcms
ENV BUILDDIR /usr/src/bergcms-build  
ENV EXPORTDIR /opt/bergcms 
    
# Get the Source
RUN mkdir -p "$BASEDIR" && cd "$BASEDIR" \
    && git clone git://github.com/leutloff/bergcms.git bergcms \
    && cd bergcms \
    && git checkout 2451997 \
    && git submodule update --init --recursive

# Build ctemplate
RUN cd "$BGDIR/src/external/ctemplate" \
    && ./configure --prefix "$BGDIR/src/external/ctemplate" 1>/dev/null \
    && make \
    && make install

RUN ls -l "$BGDIR/src/external/ctemplate" "$BGDIR/src/external/ctemplate/include/ctemplate"

# Build the Berg CMS
RUN mkdir -p "$BUILDDIR" && cd "$BUILDDIR" \
    && cmake -D CMAKE_BUILD_TYPE=Distribution -D CMAKE_VERBOSE_MAKEFILE=FALSE -D Boost_DEBUG=FALSE "$BGDIR/src" \
    && make \
    && make package \
    && export BERG_ARCHIVE=$(ls -t Berg*.zip | head -1) \
    && ls -al . "$BUILDDIR"  test "$BUILDDIR/test" 

# Running the C++ unit tests...
RUN cd "$BUILDDIR/test" \
    && ./bergunittests \
    && echo "BUILDDIR: $BUILDDIR" \
    && ls -al "$BUILDDIR"

ENTRYPOINT [ "/bin/bash", "-c", "/bin/ls /usr/src/bergcms-build/*.zip" ]
