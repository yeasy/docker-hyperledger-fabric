# Dockerfile for Hyperledger fabric development, including most necessary binaries and dev tools.
# If you need a peer node to run, please see the yeasy/hyperledger-peer, yeasy/hyperledger-orderer image.
# Workdir is set to $GOPATH/src/github.com/hyperledger/fabric
# Data is stored under /var/hyperledger/db and /var/hyperledger/production

# Currently, the binary will look for config files at corresponding path.

FROM golang:1.8
LABEL maintainer "Baohua Yang <yangbaohua@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

# Only useful for this Dockerfile
ENV FABRIC_HOME $GOPATH/src/github.com/hyperledger/fabric
ENV ARCH x86_64

# version for the base images, e.g., fabric-ccenv, fabric-baseos
ENV BASE_VERSION 0.3.0
# version for the peer/orderer binaries, the community version tracks the hash value like 1.0.0-snapshot-51b7e85
ENV PROJECT_VERSION 1.0.0-preview
# generic builder environment: builder: $(DOCKER_NS)/fabric-ccenv:$(ARCH)-$(PROJECT_VERSION)
ENV DOCKER_NS hyperledger
# for golang or car's baseos: $(BASE_DOCKER_NS)/fabric-baseos:$(ARCH)-$(BASE_VERSION)
ENV BASE_DOCKER_NS hyperledger

# peer env 
ENV PEER_CFG_PATH /etc/hyperledger/fabric
ENV CORE_PEER_MSPCONFIGPATH $PEER_CFG_PATH/msp/sampleconfig
# ignore handshake, since not using mutual TLS
ENV CORE_PEER_GOSSIP_SKIPHANDSHAKE true

# orderer env 
ENV ORDERER_CFG_PATH /etc/hyperledger/fabric/orderer
ENV ORDERER_GENERAL_LOCALMSPDIR $ORDERER_CFG_PATH/msp/sampleconfig
ENV ORDERER_GENERAL_LISTENADDRESS 0.0.0.0
ENV CONFIGTX_ORDERER_ORDERERTYPE=solo

# This is the source code dir, can map external one with -v
VOLUME $GOPATH/src/github.com/hyperledger

# The data and config dir, can map external one with -v
VOLUME /var/hyperledger
#VOLUME /etc/hyperledger/fabric

RUN mkdir -p /var/hyperledger/db \
        /var/hyperledger/production \
        $PEER_CFG_PATH \
        $ORDERER_CFG_PATH \
        $ORDERER_GENERAL_LOCALMSPDIR \
        /chaincode/input \
        /chaincode/output

RUN apt-get update \
        && apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev libyaml-dev python-dev \
        && apt-get install -y python-pip \
        && pip install --upgrade pip \
        && pip install behave nose docker-compose \
        && rm -rf /var/cache/apt

# install chaintool
RUN curl -L https://github.com/hyperledger/fabric-chaintool/releases/download/v0.10.1/chaintool > /usr/local/bin/chaintool \
        && chmod a+x /usr/local/bin/chaintool

# install gotools
RUN cd $FABRIC_HOME/ \
        && go get github.com/golang/lint/golint \
        && go get github.com/kardianos/govendor \
        && go get golang.org/x/tools/cmd/goimports \
        && go get github.com/golang/protobuf/protoc-gen-go \
        && go get github.com/onsi/ginkgo/ginkgo \
        && go get github.com/axw/gocov/... \
        && go get github.com/AlekSi/gocov-xml

# clone hyperledger fabric code
RUN mkdir -p $GOPATH/src/github.com/hyperledger \
        && cd $GOPATH/src/github.com/hyperledger \
        && git clone --single-branch -b master --depth 1 http://gerrit.hyperledger.org/r/fabric \
        && cp $FABRIC_HOME/devenv/limits.conf /etc/security/limits.conf

# install configtxgen and cryptogen
RUN cd $FABRIC_HOME/ \
        && CGO_CFLAGS=" " go install -ldflags \
        "-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASE_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
        -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger" \
        github.com/hyperledger/fabric/common/configtx/tool/configtxgen \
        && CGO_CFLAGS=" " go install -ldflags \
        "-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASE_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
        -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger" \
        github.com/hyperledger/fabric/common/tools/cryptogen

# install fabric peer and configs
RUN cd $FABRIC_HOME/peer \
        && CGO_CFLAGS=" " go install -ldflags \
        "-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASE_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
        -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=${DOCKER_NS} \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=${BASE_DOCKER_NS} \
        -linkmode external -extldflags '-static -lpthread'" \
        && go clean \
        && cp $FABRIC_HOME/peer/core.yaml $PEER_CFG_PATH \
        && mkdir -p $PEER_CFG_PATH/msp/sampleconfig \
        && cp -r $FABRIC_HOME/msp/sampleconfig/* $PEER_CFG_PATH/msp/sampleconfig \
        && mkdir -p $PEER_CFG_PATH/common/configtx/tool \
        && cp $FABRIC_HOME/common/configtx/tool/configtx.yaml $PEER_CFG_PATH/

# install hyperledger fabric orderer
RUN cd $FABRIC_HOME/orderer \
        && CGO_CFLAGS=" " go install -ldflags \
        "-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASE_VERSION} \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
        -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=${DOCKER_NS} \
        -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=${BASE_DOCKER_NS} \
        -linkmode external -extldflags '-static -lpthread'" \
        && go clean \
        && cp $FABRIC_HOME/orderer/orderer.yaml $ORDERER_CFG_PATH/ \
        && cp -r $FABRIC_HOME/msp/sampleconfig/* $ORDERER_GENERAL_LOCALMSPDIR \
        && cp $FABRIC_HOME/common/configtx/tool/configtx.yaml $ORDERER_CFG_PATH

# this is only a workaround for current hard-coded problem when using as fabric-baseimage.
RUN ln -s $GOPATH /opt/gopath

# this is to keep compatible
# RUN PATH=$FABRIC_HOME/build/bin:$PATH

WORKDIR $FABRIC_HOME
