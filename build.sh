#!/bin/sh

# accept a parameter to specify the tag
if [ -z "$1" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

TAG=$1

# build the image
echo "Building and tagging image with $TAG"
sleep 1

docker build -t motocom/nginx-php-fpm:$TAG .

# push the image
echo "Pushing image to Docker Hub"
docker push motocom/nginx-php-fpm:$TAG