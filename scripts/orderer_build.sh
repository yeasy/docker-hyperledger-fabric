#!/bin/bash 

set -e

ORDERER_BIN=`which orderer`

echo "Remove $ORDERER_BIN"
rm -f $ORDERER_BIN

echo "Building fabric orderer"
cd $FABRIC_ROOT/orderer \
    && CGO_CFLAGS=" " go install -ldflags "$LD_FLAGS -linkmode external -extldflags '-static -lpthread'" \
    && go clean
