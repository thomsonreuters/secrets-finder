#!/bin/bash
set -e

docker build -t ingestion-lambda --platform=linux/arm64 -f Dockerfile .

docker run --rm -v $(pwd):/output ingestion-lambda cp /app/ingestion.zip /output/
