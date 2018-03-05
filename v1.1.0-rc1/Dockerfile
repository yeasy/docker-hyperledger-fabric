# https://github.com/yeasy/docker-hyperledger-fabric
#
# Dockerfile for Hyperledger fabric all-in-one development and experiments, including:
# * fabric-peer
# * fabric-orderer
# * fabric-ca
# * cryptogen
# * configtxgen
# * configtxlator
# * chaintools
# * gotools

# If you only need quickly deploy a fabric network, please see
# * yeasy/hyperledger-fabric-peer
# * yeasy/hyperledger-fabric-orderer
# * yeasy/hyperledger-fabric-ca

# Workdir is set to $GOPATH/src/github.com/hyperledger/fabric
# Data is stored under /var/hyperledger/db and /var/hyperledger/production

FROM golang:1.9
LABEL maintainer "Baohua Yang <yangbaohua@gmail.com>"

# fabric-orderer
EXPOSE 7050
# fabric-peers
EXPOSE 7051 7052 7053
# fabric-ca-server RESTful
EXPOSE 7054

ENV DEBIAN_FRONTEND noninteractive

# Aliases only useful for this Dockerfile
ENV FABRIC_ROOT=$GOPATH/src/github.com/hyperledger/fabric \
    FABRIC_CA_ROOT=$GOPATH/src/github.com/hyperledger/fabric-ca

# When to become open-source?
ENV ARCH=x86_64

# version for the hyperledger/fabric-baseimages
ENV BASEIMAGE_RELEASE=0.4.5

# BASE_VERSION is required in core.yaml to run cc container
ENV BASE_VERSION=1.1.0-rc1

# version for the peer/orderer binaries, the community version tracks the hash value like 1.0.0-snapshot-51b7e85
# PROJECT_VERSION is required in core.yaml to build image for cc container
ENV PROJECT_VERSION=1.1.0-rc1

# generic builder environment: builder: $(DOCKER_NS)/fabric-ccenv:$(ARCH)-$(PROJECT_VERSION)
ENV DOCKER_NS=hyperledger

# for golang or car's baseos: $(BASE_DOCKER_NS)/fabric-baseos:$(ARCH)-$(BASE_VERSION)
ENV BASE_DOCKER_NS=hyperledger
ENV LD_FLAGS="-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
              -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASEIMAGE_RELEASE} \
              -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
              -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger \
              -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger \
              -X github.com/hyperledger/fabric/common/metadata.Experimental=false"

# peer envs. DONOT combine in one line as the former variable won't work on-the-fly
ENV FABRIC_CFG_PATH=/etc/hyperledger/fabric
ENV CORE_PEER_MSPCONFIGPATH=$FABRIC_CFG_PATH/msp \
    CORE_LOGGING_LEVEL=DEBUG

# orderer env 
ENV ORDERER_GENERAL_LOCALMSPDIR=$FABRIC_CFG_PATH/msp \
    ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 \
    ORDERER_GENERAL_GENESISPROFILE=TwoOrgsOrdererGenesis

# ca env. ca-server and ca-client will check the following env in order, to get the home cfg path
ENV FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
    FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca-server \
    FABRIC_CA_CLIENT_HOME=$HOME/.fabric-ca-client \
    CA_CFG_PATH=/etc/hyperledger/fabric-ca

RUN mkdir -p /var/hyperledger/db \
        /var/hyperledger/production \
        $GOPATH/src/github.com/hyperledger \
        $FABRIC_CFG_PATH \
        $FABRIC_CFG_PATH/crypto-config \
        /chaincode/input \
        /chaincode/output \
        $FABRIC_CA_SERVER_HOME \
        $FABRIC_CA_CLIENT_HOME \
        $CA_CFG_PATH \
        /var/hyperledger/fabric-ca-server

# Install development dependencies
RUN apt-get update \
        && apt-get install -y apt-utils python-dev \
        && apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev libyaml-dev libltdl-dev libtool \
        && apt-get install -y python-pip \
        && apt-get install -y vim tree jq unzip \
        && pip install --upgrade pip \
        && pip install behave nose docker-compose \
        && rm -rf /var/cache/apt

# Install chaintool
RUN curl -L https://github.com/hyperledger/fabric-chaintool/releases/download/v0.10.3/chaintool > /usr/local/bin/chaintool \
        && chmod a+x /usr/local/bin/chaintool

# Install tools for Golang
RUN go get github.com/golang/protobuf/protoc-gen-go \
        && go get github.com/kardianos/govendor \
        && go get github.com/golang/lint/golint \
        && go get golang.org/x/tools/cmd/goimports \
        && go get github.com/onsi/ginkgo/ginkgo \
        && go get github.com/axw/gocov/... \
        && go get github.com/client9/misspell/cmd/misspell \
        && go get github.com/AlekSi/gocov-xml

# Clone the Hyperledger Fabric code and cp sample config files
RUN cd $GOPATH/src/github.com/hyperledger \
        && wget https://github.com/hyperledger/fabric/archive/v${PROJECT_VERSION}.zip \
        && unzip v${PROJECT_VERSION}.zip \
        && rm v${PROJECT_VERSION}.zip \
        && mv fabric-${PROJECT_VERSION} fabric \
        && cp $FABRIC_ROOT/devenv/limits.conf /etc/security/limits.conf \
        && cp -r $FABRIC_ROOT/sampleconfig/* $FABRIC_CFG_PATH/ \
        && cp $FABRIC_ROOT/examples/e2e_cli/configtx.yaml $FABRIC_CFG_PATH/ \
        && cp $FABRIC_ROOT/examples/e2e_cli/crypto-config.yaml $FABRIC_CFG_PATH/

# Install configtxgen, cryptogen and configtxlator
RUN cd $FABRIC_ROOT/ \
        && go install -ldflags "${LD_FLAGS}" github.com/hyperledger/fabric/common/tools/configtxgen \
        && go install -ldflags "${LD_FLAGS}" github.com/hyperledger/fabric/common/tools/cryptogen \
        && go install -ldflags "${LD_FLAGS}" github.com/hyperledger/fabric/common/tools/configtxlator

# Install block-listener
RUN cd $FABRIC_ROOT/examples/events/block-listener \
        && go install \
        && go clean

# Install fabric peer
RUN cd $FABRIC_ROOT/peer \
        && CGO_CFLAGS=" " go install -ldflags "$LD_FLAGS -linkmode external -extldflags '-static -lpthread'" \
        && go clean

# Install fabric orderer
RUN cd $FABRIC_ROOT/orderer \
        && CGO_CFLAGS=" " go install -ldflags "$LD_FLAGS -linkmode external -extldflags '-static -lpthread'" \
        && go clean

#ADD crypto-config $FABRIC_CFG_PATH/crypto-config

# Install fabric-ca
RUN cd $GOPATH/src/github.com/hyperledger \
    && wget https://github.com/hyperledger/fabric-ca/archive/v${PROJECT_VERSION}.zip \
    && unzip v${PROJECT_VERSION}.zip \
    && rm v${PROJECT_VERSION}.zip \
    && mv fabric-ca-${PROJECT_VERSION} fabric-ca \
    # This will install fabric-ca-server and fabric-ca-client into $GOPATH/bin/
    && go install -ldflags "-X github.com/hyperledger/fabric-ca/lib/metadata.Version=$PROJECT_VERSION -linkmode external -extldflags '-static -lpthread'" github.com/hyperledger/fabric-ca/cmd/... \
    # Copy example ca and key files
    && cp $FABRIC_CA_ROOT/images/fabric-ca/payload/*.pem $FABRIC_CA_HOME/ \
    && go clean

# This is useful to debug local code with mapping inside
VOLUME $GOPATH/src/github.com/hyperledger
# The data and config dir, can map external one with -v
VOLUME /var/hyperledger
VOLUME $FABRIC_CFG_PATH
VOLUME $FABRIC_CA_SERVER_HOME
VOLUME $FABRIC_CA_CLIENT_HOME

# Useful scripts for quickly compiling local code
ADD scripts/*.sh /tmp/

# Remove the go pkg files in case polluting debugging env
RUN bash /tmp/clean_pkg.sh

# Temporarily fix the `go list` complain problem, which is required in chaincode packaging, see core/chaincode/platforms/golang/platform.go#GetDepoymentPayload
ENV GOROOT=/usr/local/go

WORKDIR $FABRIC_ROOT

# This is only a workaround for current hard-coded problem when using as fabric-baseimage.
RUN ln -s $GOPATH /opt/gopath

LABEL org.hyperledger.fabric.version=${PROJECT_VERSION} \
      org.hyperledger.fabric.base.version=${BASEIMAGE_RELEASE}
