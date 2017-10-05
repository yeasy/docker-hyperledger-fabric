#!/bin/bash 

set -e

PEER_BIN=`which peer`

echo "Remove $PEER_BIN"
rm -f $PEER_BIN

echo "Building fabric peer"
cd $FABRIC_ROOT/peer \
    && CGO_CFLAGS=" " go install -ldflags "$LD_FLAGS -linkmode external -extldflags '-static -lpthread'" \
    && go clean 
