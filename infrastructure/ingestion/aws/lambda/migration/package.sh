#!/bin/bash
set -e

ROOT_DIR=$(git rev-parse --show-toplevel)

docker build -t migrate-lambda --platform=linux/arm64 -f Dockerfile $ROOT_DIR/migrations

docker run --rm -v $(pwd):/output migrate-lambda cp /app/migration.zip /output/
