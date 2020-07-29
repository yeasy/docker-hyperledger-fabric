#!/bin/bash
# This script will read the files from env variables and store them under $FABRIC_CFG_PATH.
# Will run the optional passed command if everything is OK.
#
# It will read the following env variables
# HLF_NODE_MSP: store a base64 encoded zipped "msp" path
# HLF_NODE_TLS: store a base64 encoded zipped "tls" path
# HLF_NODE_BOOTSTRAP_BLOCK: store a base64 encoded zipped bootstrap block
# HLF_NODE_PEER_CONFIG: store a base64 encoded zipped peer configuration file (core.yaml)
# HLF_NODE_ORDERER_CONFIG: store a base64 encoded zipped orderer configuration file (orderer.yaml)

# The optional cmd to run after storing every file
cmd=$1

# The path to store the files
cfg_path=${FABRIC_CFG_PATH:-/etc/hyperledger/fabric}

# Read each file from env and store under the ${cfg_path}
for name in ${HLF_NODE_MSP} ${HLF_NODE_TLS} ${HLF_NODE_BOOTSTRAP_BLOCK} ${HLF_NODE_PEER_CONFIG} ${HLF_NODE_ORDERER_CONFIG}
do
    echo "Store ${name}"
	storeFile $name
done

# Run optional cmd
if [[ -z "${cmd}" ]]; then
    echo "Run ${cmd}"
    ${cmd}
fi

# variable-name to decode and then unzip to ${cfg_path}
function storeFile {
    if [[ -z "$1" ]]; then
        echo "The variable is undefined"
        return
    else
        echo "$1" | base64 -d > /tmp/1.zip
        unzip -o -d $2 /tmp/1.zip
        rm /tmp/1.zip
        ls $cfg_path
    fi
}


