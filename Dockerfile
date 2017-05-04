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
ENV LD_FLAGS="-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
             -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASE_VERSION} \
             -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
             -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger \
             -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger"

# peer env 
ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
ENV CORE_PEER_MSPCONFIGPATH $FABRIC_CFG_PATH/msp
# ignore handshake, since not using mutual TLS
ENV CORE_PEER_GOSSIP_SKIPHANDSHAKE true
ENV CORE_LOGGING_LEVEL DEBUG

# orderer env 
ENV ORDERER_GENERAL_GENESISPROFILE=SampleInsecureSolo
ENV ORDERER_GENERAL_LOCALMSPDIR $ORDERER_CFG_PATH/msp
ENV ORDERER_GENERAL_LISTENADDRESS 0.0.0.0
ENV CONFIGTX_ORDERER_ORDERERTYPE=solo

# The data and config dir, can map external one with -v
VOLUME /var/hyperledger
#VOLUME /etc/hyperledger/fabric

RUN mkdir -p /var/hyperledger/db \
        /var/hyperledger/production \
        $GOPATH/src/github.com/hyperledger \
        $FABRIC_CFG_PATH \
        /chaincode/input \
        /chaincode/output

RUN apt-get update \
        && apt-get install -y apt-utils python-dev \
        && apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev libyaml-dev libltdl-dev \
        && apt-get install -y python-pip \
        && apt-get install -y vim \
        && pip install --upgrade pip \
        && pip install behave nose docker-compose \
        && rm -rf /var/cache/apt

# install chaintool
RUN curl -L https://github.com/hyperledger/fabric-chaintool/releases/download/v0.10.1/chaintool > /usr/local/bin/chaintool \
        && chmod a+x /usr/local/bin/chaintool

# install gotools
RUN go get github.com/golang/lint/golint \
        && go get github.com/kardianos/govendor \
        && go get github.com/golang/protobuf/protoc-gen-go \
        && go get github.com/onsi/ginkgo/ginkgo \
        && go get github.com/axw/gocov/... \
        && go get github.com/AlekSi/gocov-xml \
        && go get golang.org/x/tools/cmd/goimports

# clone hyperledger fabric code and cp configs
RUN cd $GOPATH/src/github.com/hyperledger \
        && git clone --single-branch -b master --depth 1 http://gerrit.hyperledger.org/r/fabric \
        && cp $FABRIC_HOME/devenv/limits.conf /etc/security/limits.conf \
        && cp -r $FABRIC_HOME/sampleconfig/* $FABRIC_CFG_PATH/

# install configtxgen and cryptogen
RUN cd $FABRIC_HOME/ \
        && CGO_CFLAGS=" " go install -tags "nopkcs11" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/common/configtx/tool/configtxgen \
        && CGO_CFLAGS=" " go install -tags "nopkcs11" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/common/tools/cryptogen

# install fabric peer
RUN cd $FABRIC_HOME/peer \
        && CGO_CFLAGS=" " go install -ldflags "$LD_FLAGS -linkmode external -extldflags '-static -lpthread'" \
        && go clean

# install fabric orderer
RUN cd $FABRIC_HOME/orderer \
        && CGO_CFLAGS=" " go install -ldflags "$LD_FLAGS -linkmode external -extldflags '-static -lpthread'" \
        && go clean

# this is only a workaround for current hard-coded problem when using as fabric-baseimage.
RUN ln -s $GOPATH /opt/gopath

# This is useful to debug local code
VOLUME $GOPATH/src/github.com/hyperledger

# Useful scripts for debugging local code
ADD *.sh /tmp/

WORKDIR $FABRIC_HOME
