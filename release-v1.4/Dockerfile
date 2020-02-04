# https://github.com/yeasy/docker-hyperledger-fabric
#
# Dockerfile for Hyperledger fabric all-in-one development and experiments, including:
# * fabric-peer
# * fabric-orderer
# * fabric-ca
# * cryptogen
# * configtxgen
# * configtxlator
# * gotools

# If you only need quickly deploy a fabric network, please see
# * yeasy/hyperledger-fabric-peer
# * yeasy/hyperledger-fabric-orderer
# * yeasy/hyperledger-fabric-ca

# Workdir is set to $GOPATH/src/github.com/hyperledger/fabric
# Data is stored under /var/hyperledger/production

FROM golang:1.12
LABEL maintainer "Baohua Yang <yangbaohua@gmail.com>"

# Orderer, peer, ca, operation api
EXPOSE 7050 7051 7054 8443 9443

ENV DEBIAN_FRONTEND noninteractive

# Only useful for this Dockerfile
ENV FABRIC_ROOT=$GOPATH/src/github.com/hyperledger/fabric \
    FABRIC_CA_ROOT=$GOPATH/src/github.com/hyperledger/fabric-ca

# Architecture of the node
ENV ARCH=amd64
# version for the base images (baseos, baseimage, ccenv, etc.)
ENV BASEIMAGE_RELEASE=0.4.18

# BASE_VERSION is used in metadata.Version as major version
ENV BASE_VERSION=1.4.4

# version for the peer/orderer binaries, the community version tracks the hash value like 1.0.0-snapshot-51b7e85
# PROJECT_VERSION is required in core.yaml for fabric-baseos and fabric-ccenv
ENV PROJECT_VERSION=1.4.4

# generic environment (core.yaml) for builder and runtime: builder: $(DOCKER_NS)/fabric-ccenv:$(TWO_DIGIT_VERSION)
ENV DOCKER_NS=hyperledger

# for golang or car's baseos for cc runtime: $(BASE_DOCKER_NS)/fabric-baseos:$(BASEIMAGE_RELEASE)
ENV BASE_DOCKER_NS=hyperledger
ENV LD_FLAGS="-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
              -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASEIMAGE_RELEASE} \
              -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
              -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger \
              -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger"

# -X github.com/hyperledger/fabric/common/metadata.Experimental=true \
# -linkmode external -extldflags '-static -lpthread'"

# peer envs. DONOT combine in one line as the former variable won't work on-the-fly
ENV FABRIC_CFG_PATH=/etc/hyperledger/fabric

# peer env
ENV CORE_PEER_MSPCONFIGPATH=$FABRIC_CFG_PATH/msp \
    FABRIC_LOGGING_SPEC=DEBUG

# orderer env
ENV ORDERER_GENERAL_LOCALMSPDIR=$FABRIC_CFG_PATH/msp \
    ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 \
    ORDERER_GENERAL_GENESISPROFILE=TwoOrgsOrdererGenesis

# ca env. ca-server and ca-client will check the following env in order, to get the home cfg path
ENV FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
    FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca-server \
    FABRIC_CA_CLIENT_HOME=/root/.fabric-ca-client \
    CA_CFG_PATH=/etc/hyperledger/fabric-ca

RUN mkdir -p /var/hyperledger/production \
        $GOPATH/src/github.com/hyperledger \
        $FABRIC_CFG_PATH \
        $FABRIC_CFG_PATH/crypto-config \
        $FABRIC_CA_SERVER_HOME \
        $FABRIC_CA_CLIENT_HOME \
        $CA_CFG_PATH \
        /chaincode/input \
        /chaincode/output \
        /var/hyperledger/fabric-ca-server

# Install development dependencies
RUN apt-get update \
        && apt-get install -y apt-utils python-dev \
        && apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev libyaml-dev libltdl-dev libtool \
        && apt-get install -y python-pip \
        && apt-get install -y vim tree jq unzip \
        && pip install behave nose docker-compose \
        && pip install pyinotify \
        && rm -rf /var/cache/apt

# Install yq to update config for fabric-ca
RUN wget -O /go/bin/yq https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 \
        && chmod a+x /go/bin/yq

# install gotools
RUN go get github.com/golang/protobuf/protoc-gen-go \
        && go get github.com/maxbrunsfeld/counterfeiter \
        && go get github.com/axw/gocov/... \
        && go get github.com/AlekSi/gocov-xml \
        && go get golang.org/x/tools/cmd/goimports \
        && go get golang.org/x/lint/golint \
        && go get github.com/estesp/manifest-tool \
        && go get github.com/client9/misspell/cmd/misspell \
        && go get github.com/estesp/manifest-tool \
        && go get github.com/onsi/ginkgo/ginkgo

# Clone the Hyperledger Fabric code and cp sample config files
RUN cd $GOPATH/src/github.com/hyperledger \
        && git clone --single-branch -b release-1.4 --depth 1 https://github.com/hyperledger/fabric.git \
        && cp $FABRIC_ROOT/devenv/limits.conf /etc/security/limits.conf \
        && cp -r $FABRIC_ROOT/sampleconfig/* $FABRIC_CFG_PATH/ \
        && cp $FABRIC_ROOT/examples/cluster/config/configtx.yaml $FABRIC_CFG_PATH/ \
        && cp $FABRIC_ROOT/examples/cluster/config/cryptogen.yaml $FABRIC_CFG_PATH/

# Install configtxgen, cryptogen, configtxlator and discover
RUN cd $FABRIC_ROOT/ \
        && CGO_CFLAGS=" " go install -tags "" -ldflags "${LD_FLAGS}" github.com/hyperledger/fabric/common/tools/configtxgen \
        && CGO_CFLAGS=" " go install -tags "" -ldflags "${LD_FLAGS}" github.com/hyperledger/fabric/common/tools/cryptogen \
        && CGO_CFLAGS=" " go install -tags "" -ldflags "${LD_FLAGS}" github.com/hyperledger/fabric/common/tools/configtxlator \
	&& CGO_CFLAGS=" " go install -tags "" -ldflags "-X github.com/hyperledger/fabric/cmd/discover/metadata.Version=${BASE_VERSION}" github.com/hyperledger/fabric/cmd/discover

# Install eventsclient
RUN cd $FABRIC_ROOT/examples/events/eventsclient \
        && go install \
        && go clean

# Install fabric peer
RUN CGO_CFLAGS=" " go install -tags "" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/cmd/peer \
        && go clean

# Install fabric orderer
RUN CGO_CFLAGS=" " go install -tags "" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/cmd/orderer \
        && go clean

#ADD crypto-config $FABRIC_CFG_PATH/crypto-config

# Install fabric-ca
RUN cd $GOPATH/src/github.com/hyperledger \
	&& git clone --single-branch -b release-1.4 --depth 1 https://github.com/hyperledger/fabric-ca.git \
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
ADD scripts/ /tmp/

# Remove the go pkg files in case polluting debugging env
RUN bash /tmp/clean_pkg.sh

# Temporarily fix the `go list` complain problem, which is required in chaincode packaging, see core/chaincode/platforms/golang/platform.go#GetDepoymentPayload
ENV GOROOT=/usr/local/go

WORKDIR $FABRIC_ROOT

# This is only a workaround for current hard-coded problem when using as fabric-baseimage.
RUN ln -s $GOPATH /opt/gopath

LABEL org.hyperledger.fabric.version=${PROJECT_VERSION} \
      org.hyperledger.fabric.base.version=${BASEIMAGE_RELEASE}
