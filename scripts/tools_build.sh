#!/bin/bash

BASE_VERSION=0.3.1
PROJECT_VERSION=1.0.0-preview
PROJECT_VERSION=1.0.0-preview
DOCKER_NS=hyperledge
BASE_DOCKER_NS=hyperledger

LD_FLAGS="-X github.com/hyperledger/fabric/common/metadata.Version=${PROJECT_VERSION} \
    -X github.com/hyperledger/fabric/common/metadata.BaseVersion=${BASE_VERSION} \
    -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric \
    -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger \
    -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger"

echo "Building configtxgen"
CGO_CFLAGS=" " go install -tags "nopkcs11" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/common/configtx/tool/configtxgen

echo "Building cryptogen"
CGO_CFLAGS=" " go install -tags "" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/common/tools/cryptogen

echo "Building configtxlator"
CGO_CFLAGS=" " go install -tags "" -ldflags "$LD_FLAGS" github.com/hyperledger/fabric/common/tools/configtxlator
