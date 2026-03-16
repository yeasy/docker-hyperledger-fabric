#!/bin/bash 

set -e

PEER_BIN=`which peer`

echo "Remove $PEER_BIN"
rm -f $PEER_BIN

echo "Building fabric peer"

cd $FABRIC_ROOT/cmd/peer \
    && CGO_CFLAGS=" " go install -tags "" -ldflags "$LD_FLAGS" \
    && go clean
