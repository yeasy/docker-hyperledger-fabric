Docker-Hyperledger-Fabric
===
Docker images for [Hyperledger Fabric](https://www.hyperledger.org).

# Supported tags and respective Dockerfile links

* [`latest` (latest/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/Dockerfile): Default to enable pbft as consensus.
* [`0.6-dp` (0.6-dp/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/0.6-dp/Dockerfile): Use 0.6-developer-preview branch code.

For more information about this image and its history, please see the relevant manifest file in the [`yeasy/docker-hyperledger-fabric` GitHub repo](https://github.com/yeasy/docker-hyperledger-fabric).

If you want to quickly deploy a local cluster without any configuration and vagrant, please refer to [Start hyperledger clsuter using compose](https://github.com/yeasy/docker-compose-files#hyperledger).

# What is docker-hyperledger-fabric?
Docker image with hyperledger fabric peer, ca and base image inside. 

# How to use this image?
The docker image is auto built at [https://registry.hub.docker.com/u/yeasy/hyperledger-fabric/](https://registry.hub.docker.com/u/yeasy/hyperledger-fabric/).

## In Dockerfile
```sh
FROM yeasy/hyperledger-fabric:latest
```

## Local Run with single node
The `peer` command is the main command, you can use it as the start part.

E.g., see the supported sub commands with the `help` command.
```sh
$ peer help
02:10:10.359 [crypto] main -> INFO 001 Log level recognized 'info', set to INFO


Usage:
  peer [command]

Available Commands:
  node        node specific commands.
  network     network specific commands.
  chaincode   chaincode specific commands.
  help        Help about any command

Flags:
      --logging-level="": Default logging level and overrides, see core.yaml for full syntax


Use "peer [command] --help" for more information about a command.
```

Hyperledger relies on a `core.yaml` file, you can mount your local one by
```sh
$ docker run -v your_local_core.yaml:/go/src/github.com/hyperledger/fabric/peer/core.yaml -d yeasy/hyperledger-fabric peer node start help
```

The storage will be under `/var/hyperledger/`, which should be mounted from host for persistent requirement.

Your can also mapping the port outside using the `-p` options. 

* 7050: REST service listening port (Recommened to open at non-validating node)
* 7051: Peer service listening port
* 7052: CLI process use it for callbacks from chain code
* 7053: Event service on validating node

## Local Run with chaincode testing

Start your docker daemon with

```sh
$ sudo docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
```

Pull necessary images, notice the default config require a local built `hyperledger/fabric-baseimage` and `hyperledger/fabric-peer`. We can just use the `yeasy/hyperledger-fabric` image instead.

```sh
$ docker pull yeasy/hyperledger-fabric:latest
$ docker tag yeasy/hyperledger-fabric:latest hyperledger/fabric-baseimage:latest
$ docker tag yeasy/hyperledger-fabric:latest hyperledger/fabric-peer:latest
```

Check the `docker0` bridge ip, normally it should be `172.17.0.1`. This ip will be used as the `CORE_VM_ENDPOINT=http://172.17.0.1:2375`.
```sh
$  ip addr show dev docker0
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:f2:90:57:cf brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
    valid_lft forever preferred_lft forever
    inet6 fe80::42:f2ff:fe90:57cf/64 scope link
    valid_lft forever preferred_lft forever
```

Start a validating node.

### Noops consensus

```sh
$ docker run --name=vp0 \
                    --restart=unless-stopped \
                    -it \
                    -p 7050:7050 \
                    -p 7051:7051 \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -e CORE_PEER_ID=vp0 \
                    -e CORE_PEER_ADDRESSAUTODETECT=true \
                    -e CORE_NOOPS_BLOCK_TIMEOUT=10 \
                    yeasy/hyperledger-fabric:latest peer node start
```

Or use your docker daemon url.

```sh
$ docker run --name=vp0 \
                    --restart=unless-stopped \
                    -it \
                    -p 7050:7050 \
                    -p 7051:7051 \
                    -e CORE_PEER_ID=vp0 \
                    -e CORE_VM_ENDPOINT=http://172.17.0.1:2375 \
                    -e CORE_PEER_ADDRESSAUTODETECT=true \
                    -e CORE_NOOPS_BLOCK_TIMEOUT=10 \
                    yeasy/hyperledger-fabric:latest peer node start
```

### PBFT consensus
PBFT requires at least 4 nodes.

```sh
$ git clone https://github.com/yeasy/docker-compose-files
$ cd docker-compose-files/hyperledger
$ docker-compose up
```

More details, please refer to [hyperledger-compose-files](https://github.com/yeasy/docker-compose-files#hyperledger).

After the cluster starts up, enter into the container
```sh
$ docker exec -it vp0 bash
```
    
Inside the container, deploy a chaincode using

```sh
$ peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Function":"init", "Args": ["a","100", "b", "200"]}'
13:16:35.643 [crypto] main -> INFO 001 Log level recognized 'info', set to INFO
5844bc142dcc9e788785e026e22c855957b2c754c912702c58d997dedbc9a042f05d152f6db0fbd7810d95c1b880c210566c9de3093aae0ab76ad2d90e9cfaa5
```

Query `a`'s current value, which is 100.
```sh
$ peer chaincode query -n 5844bc142dcc9e788785e026e22c855957b2c754c912702c58d997dedbc9a042f05d152f6db0fbd7810d95c1b880c210566c9de3093aae0ab76ad2d90e9cfaa5 -c '{"Function": "query", "Args": ["a"]}'
13:20:07.952 [crypto] main -> INFO 001 Log level recognized 'info', set to INFO
100
```

Invoke a transaction of 10 from `a` to `b`.
```sh
$ peer chaincode invoke -n 5844bc142dcc9e788785e026e22c855957b2c754c912702c58d997dedbc9a042f05d152f6db0fbd7810d95c1b880c210566c9de3093aae0ab76ad2d90e9cfaa5 -c '{"Function": "invoke", "Args": ["a", "b", "10"]}'
13:20:31.028 [crypto] main -> INFO 001 Log level recognized 'info', set to INFO
ec3c675b-a2fe-4429-ab44-7f389e454657
```
Query `a` 's value now.
```sh
$ peer chaincode query -n 5844bc142dcc9e788785e026e22c855957b2c754c912702c58d997dedbc9a042f05d152f6db0fbd7810d95c1b880c210566c9de3093aae0ab76ad2d90e9cfaa5 -c '{"Function": "query", "Args": ["a"]}'
13:20:35.725 [crypto] main -> INFO 001 Log level recognized 'info', set to INFO
90
```

More examples, please refer to [hyperledger-compose-files](https://github.com/yeasy/docker-compose-files#hyperledger).


If you wanna manually start.

For root node:

```sh
docker run --name=node_vp0 \
                    -e CORE_PEER_ID=vp0 \
                    -e CORE_PBFT_GENERAL_N=4 \
                    --net="host" \
                    --restart=unless-stopped \
                    -it --rm \
                    -p 5500:7050 \
                    -p 7051:7051 \
                    -v /var/run/docker.sock:/var/run/docker.sock
                    -e CORE_LOGGING_LEVEL=debug \
                    -e CORE_PEER_ADDRESSAUTODETECT=true \
                    -e CORE_PEER_NETWORKID=dev \
                    -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft \
                    -e CORE_PBFT_GENERAL_MODE=classic \
                    -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=10s \
                    yeasy/hyperledger-fabric:latest peer node start
```

for non-root node:

```sh
docker run --name=node_vpX \
                    -e CORE_PEER_ID=vpX \
                    -e CORE_PBFT_GENERAL_N=4 \
                    --net="host" \
                    --restart=unless-stopped \
                    --rm -it \
                    -p 7051:7051 \
                    --net="hyperledger_cluster_net_pbft" \
                    -e CORE_LOGGING_LEVEL=debug \
                    -e CORE_PEER_ADDRESSAUTODETECT=true \
                    -e CORE_PEER_NETWORKID=dev \
                    -e CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN=pbft \
                    -e CORE_PBFT_GENERAL_MODE=classic \
                    -e CORE_PBFT_GENERAL_TIMEOUT_REQUEST=10s \
                    -e CORE_PEER_DISCOVERY_ROOTNODE=vp0:7051 \
                    yeasy/hyperledger-fabric:latest peer node start
```



# Which image is based on?
The image is built based on [hyperledger](https://hub.docker.com/r/yeasy/hyperledger) base image.

# What has been changed?
## install dependencies
Install required  libsnappy-dev, zlib1g-dev, libbz2-dev.

## install rocksdb
Install required  rocksdb 4.1.

## install hyperledger
Install hyperledger and build the peer 

# Supported Docker versions

This image is officially supported on Docker version 1.7.0.

Support for older versions (down to 1.0) is provided on a best-effort basis.

# Known Issues
* N/A.

# User Feedback
## Documentation
Be sure to familiarize yourself with the [repository's `README.md`](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/README.md) file before attempting a pull request.

## Issues
If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/yeasy/docker-hyperledger-fabric/issues).

You can also reach many of the official image maintainers via the email.

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/yeasy/docker-hyperledger-fabric/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
