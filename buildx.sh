#!/bin/sh
set -e
docker buildx build --platform linux/amd64,linux/arm64 -t ianburgwin/firmbuilder:latest --push - < Dockerfile
