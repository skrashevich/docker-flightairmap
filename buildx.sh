#!/bin/sh

REPO=skrashevich
IMAGE=flightairmap
PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"

set -e

# Build the image using buildx
docker buildx build -t "${REPO}/${IMAGE}:latest" --push --platform "${PLATFORMS}" .
docker pull "${REPO}/${IMAGE}:latest"
