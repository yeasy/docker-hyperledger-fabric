Hyperledger Fabric
===
Docker images for developing [Hyperledger Fabric](https://www.hyperledger.org).

If you want to run fabric instead of dev/compiling, please refer to [hyperledger-compose-files](https://github.com/yeasy/docker-compose-files#hyperledger).

# Supported tags and respective Dockerfile links

* [`latest` (latest/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/Dockerfile): Tracking latest master branch code.
* [`1.0.0` (v1.0.0/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/v1.0.0/Dockerfile): Build for the 1.0.0 release.
* [`1.0.0-rc1` (v1.0.0-rc1/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/v1.0.0-rc1/Dockerfile): Build for the 1.0.0-rc1 release.
* [`1.0.0-beta` (v1.0.0-beta/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/v1.0.0-beta/Dockerfile): Build for the 1.0.0-beta release.
* [`1.0.0-alpha2` (v1.0.0-alpha2/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/v1.0.0-alpha2/Dockerfile): Build for the 1.0.0-alpha2 release.
* [`1.0.0-alpha` (v1.0.0-alpha/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/master/v1.0.0-alpha/Dockerfile): Build for the 1.0.0-alpha release.
* [`0.6-dp` (0.6-dp/Dockerfile)](https://github.com/yeasy/docker-hyperledger-fabric/blob/0.6-dp/Dockerfile): Use 0.6-developer-preview branch code.

For more information about this image and its history, please see the relevant manifest file in the [`yeasy/docker-hyperledger-fabric` GitHub repo](https://github.com/yeasy/docker-hyperledger-fabric).

If you want to quickly deploy a local cluster without any configuration and vagrant, please refer to [Start hyperledger clsuter using compose](https://github.com/yeasy/docker-compose-files#hyperledger).

# What is docker-hyperledger-fabric?
Docker image with hyperledger fabric dev environment.

# How to use this image?
The docker image is auto built at [https://registry.hub.docker.com/u/yeasy/hyperledger-fabric/](https://registry.hub.docker.com/u/yeasy/hyperledger-fabric/).

## In Dockerfile
```sh
FROM yeasy/hyperledger-fabric:latest
```

## Local development
First, make sure u install Docker, and the daemon config is as the following.

```sh
$ sudo docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
```

This image has already install the dev env, typically can just map your source code and run.

e.g, if your fabric code is at `your-fabric-code-path`, you can run `make peer` with the following cmd.

```sh
$ docker run -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v your-fabric-code-path:/go/src/github.com/hyperledger/fabric \
        yeasy/hyperledger-fabric \
        make peer
```

You can also map your local data dir to `/var/hyperledger/`, and config dir to `/etc/hyperledger`.


# Which image is based on?
The image is built based on [golang](https://hub.docker.com/_/golang) image.

# What has been changed?
## install dependencies
Install required libsnappy-dev, zlib1g-dev, libbz2-dev.

## install gotools
Install required gotools

## install hyperledger fabric
Install hyperledger fabric and build the peer, order and ca.

# Supported Docker versions

This image is officially supported on Docker version 1.7.0+.

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
