#!/bin/bash -e

echo "Build the Berg CMS for a Debian based System..."

docker build --tag=bergcms-build-debian .
docker images
mkdir -p bergcms-build
ARCHIVE=$(docker run --name=co-bergcms-build-debian  bergcms-build-debian)
docker cp co-bergcms-build-debian:$ARCHIVE bergcms-build/
ls -l bergcms-build
docker rm co-bergcms-build-debian
