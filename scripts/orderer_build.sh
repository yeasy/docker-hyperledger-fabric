#!/bin/bash 

set -e

ORDERER_BIN=`which orderer`

echo "Remove $ORDERER_BIN"
rm -f $ORDERER_BIN

echo "Building fabric orderer"
cd $FABRIC_ROOT/cmd/orderer \
    && CGO_CFLAGS=" " go install -tags "" -ldflags "$LD_FLAGS" \
    && go clean
