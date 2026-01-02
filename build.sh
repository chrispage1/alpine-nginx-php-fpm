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

# build our image and push...
docker buildx build --platform linux/amd64 -t motocom/nginx-php-fpm:$TAG --push .

echo "Image has been built and pushed!"