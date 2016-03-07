# bergcms-build-debian
Build the Berg CMS for a Debian based System.

To install Docker, see (Install Docker Engine)[https://docs.docker.com/engine/installation]

To start the build run the following docker command:

    docker build --tag=bergcms-build-debian .
    docker images
    ARCHIVE=$(docker run --name=co-bergcms-build-debian  bergcms-build-debian)
    docker cp co-bergcms-build-debian:$ARCHIVE bergcms-build 
    ls -l bergcms-build
    docker rm co-bergcms-build-debian