#!/bin/bash
# Build and publish the Docker image
docker build -t zorlin/node-evictor .
docker push zorlin/node-evictor