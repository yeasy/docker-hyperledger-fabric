# Dockerfile for Hyperledger fabric development.
# If you need a peer node to run, please see the yeasy/hyperledger-peer image.
# Workdir is set to $GOPATH/src/github.com/hyperledger/fabric
# Data is stored under /var/hyperledger/db and /var/hyperledger/production

# Currently, the binary will look for config files at corresponding path.

FROM golang:1.7
MAINTAINER Baohua Yang

ENV DEBIAN_FRONTEND noninteractive

# This is the source code dir, can map external one with -v
VOLUME $GOPATH/src/github.com/hyperledger

# The data and config dir, can map external one with -v
VOLUME /var/hyperledger
VOLUME /etc/hyperledger

RUN apt-get update \
        && apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev \
        && apt-get install -y python-pip \
        && pip install --upgrade pip \
        && pip install behave nose docker-compose \
        && rm -rf /var/cache/apt

# install some dev tools, optionally
RUN curl -L https://github.com/hyperledger/fabric-chaintool/releases/download/v0.10.1/chaintool > /usr/local/bin \
        && chmod a+x /usr/local/bin/chaintool

# install rocksdb
#RUN cd /tmp \
#        && git clone --single-branch -b v4.1 --depth 1 https://github.com/facebook/rocksdb.git \
#        && cd rocksdb \
#        && PORTABLE=1 make shared_lib \
#        && INSTALL_PATH=/usr/local make install-shared \
#        && ldconfig \
#        && cd / \
#        && rm -rf /tmp/rocksdb

RUN mkdir -p /var/hyperledger/db \
        && mkdir -p /var/hyperledger/production \
        && mkdir -p /etc/hyperledger/fabric

# clone hyperledger code
RUN mkdir -p $GOPATH/src/github.com/hyperledger \
        && cd $GOPATH/src/github.com/hyperledger \
        && git clone --single-branch -b master --depth 1 http://gerrit.hyperledger.org/r/fabric \
        && cp $GOPATH/src/github.com/hyperledger/fabric/devenv/limits.conf /etc/security/limits.conf \
# install gotools
        && cd $GOPATH/src/github.com/hyperledger/fabric/ \
        && make gotools \
# build peer
        && cd $GOPATH/src/github.com/hyperledger/fabric/peer \
#&& CGO_CFLAGS=" " CGO_LDFLAGS="-lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy" go install \
        && CGO_CFLAGS=" " go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.0-snapshot-preview -linkmode external -extldflags '-static -lpthread'" \
        && cp $GOPATH/src/github.com/hyperledger/fabric/peer/core.yaml $GOPATH/bin \
        && go clean \
# build orderer
        && cd $GOPATH/src/github.com/hyperledger/fabric/orderer \
        && go install \
        && cp $GOPATH/src/github.com/hyperledger/fabric/order/orderer.yaml $GOPATH/bin \
        && go clean

# this is only a workaround for current hard-coded problem when using as fabric-baseimage.
RUN ln -s $GOPATH /opt/gopath

# this is to keep compatible
# RUN PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:$PATH

WORKDIR $GOPATH/src/github.com/hyperledger/fabric
