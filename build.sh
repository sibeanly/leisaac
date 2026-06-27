#!/bin/bash
set -e
cd /home/ly/code/leisaac
docker build -t leisaac:v1.0 -f Dockerfile . 2>&1 | tee /tmp/build.log
echo "EXIT_CODE=$?"
