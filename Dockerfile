# Dockerfile for Hyperledger fabric development, including most necessary binaries and dev tools.
# If you need a peer node to run, please see the yeasy/hyperledger-peer, yeasy/hyperledger-orderer image.
# Workdir is set to $GOPATH/src/github.com/hyperledger/fabric
# Data is stored under /var/hyperledger/db and /var/hyperledger/production

# Currently, the binary will look for config files at corresponding path.

FROM golang:1.7
MAINTAINER Baohua Yang <yeasy.github.com>

ENV DEBIAN_FRONTEND noninteractive

ENV PEER_CFG_PATH /etc/hyperledger/fabric
ENV CORE_PEER_MSPCONFIGPATH $PEER_CFG_PATH/msp/sampleconfig
ENV ORDERER_CFG_PATH /etc/hyperledger/fabric/orderer

ENV FABRIC_PATH $GOPATH/src/github.com/hyperledger/fabric

# This is the source code dir, can map external one with -v
VOLUME $GOPATH/src/github.com/hyperledger

# The data and config dir, can map external one with -v
VOLUME /var/hyperledger
VOLUME /etc/hyperledger/fabric

RUN mkdir -p /var/hyperledger/db /var/hyperledger/production $PEER_CFG_PATH $ORDERER_CFG_PATH

RUN apt-get update \
        && apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev \
        && apt-get install -y python-pip \
        && pip install --upgrade pip \
        && pip install behave nose docker-compose \
        && rm -rf /var/cache/apt

# install chaintool
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


# clone hyperledger code
RUN mkdir -p $GOPATH/src/github.com/hyperledger \
        && cd $GOPATH/src/github.com/hyperledger \
        && git clone --single-branch -b master --depth 1 http://gerrit.hyperledger.org/r/fabric \
        && cp $FABRIC_PATH/devenv/limits.conf /etc/security/limits.conf \
# install gotools
        && cd $FABRIC_PATH/ \
        && make gotools \
        && make clean \
# build peer
        && cd $FABRIC_PATH/peer \
#&& CGO_CFLAGS=" " CGO_LDFLAGS="-lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy" go install \
        && CGO_CFLAGS=" " go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.0-snapshot-preview -linkmode external -extldflags '-static -lpthread'" \
        && go clean \
        && cp $FABRIC_PATH/peer/core.yaml $PEER_CFG_PATH \
        && mkdir -p $PEER_CFG_PATH/msp/sampleconfig \
        && cp -r $FABRIC_PATH/msp/sampleconfig/* $PEER_CFG_PATH/msp/sampleconfig \
        && mkdir -p $PEER_CFG_PATH/common/configtx/test \
        && cp $FABRIC_PATH/common/configtx/test/orderer.template $PEER_CFG_PATH/common/configtx/test \
# build orderer
        && cd $FABRIC_PATH/orderer \
        && CGO_CFLAGS=" " go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.0-snapshot-preview -linkmode external -extldflags '-static -lpthread'" \
        && go clean \
        && cp $FABRIC_PATH/order/orderer.yaml $ORDERER_CFG_PATH \
        && mkdir -p $ORDERER_CFG_PATH/msp/sampleconfig \
        && cp -r $FABRIC_PATH/msp/sampleconfig/* $ORDERER_CFG_PATH/msp/sampleconfig

# this is only a workaround for current hard-coded problem when using as fabric-baseimage.
RUN ln -s $GOPATH /opt/gopath

# this is to keep compatible
# RUN PATH=$FABRIC_PATH/build/bin:$PATH

WORKDIR $FABRIC_PATH
