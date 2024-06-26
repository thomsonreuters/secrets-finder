#!/bin/bash
set -e

function write {
  printf "%-10s %s\n" "[$1]" "$2"
}

function show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --output      Output filename (default: secrets-finder-<date>-<sha256>.zip)"
  echo "  --help        Display this help and exit"
  echo ""
}

echo "****************************************"
echo "*   Packaging of AWS Lambda function   *"
echo "****************************************"
if ! grep -E -i "(debian|ubuntu)" /etc/*-release &>/dev/null && ! [[ "$OSTYPE" =~ ^darwin ]]; then
    write "ERROR" "Unsupported operating system ($OSTYPE). Only macOS and Linux operating systems are supported."
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    write "ERROR" "Python 3 is not installed. Operation aborted." >&2
    exit 1
fi

if ! command -v pip &>/dev/null; then
    write "ERROR" "pip is not installed. Operation aborted." >&2
    exit 1
fi

LAMBDA_DIRECTORY=$(pwd)

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -o | --output)
        OUTPUT="$2"
        shift
        shift
        ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        echo "Invalid option: $1"
        exit 1
        ;;
    esac
done

if [ -z "$OUTPUT" ]; then
    if [[ "$OSTYPE" =~ ^darwin ]]; then
        SHORT_SHA256_LAMBDA_FUNCTION=$(shasum -a 256 secrets-finder.py | cut -c1-8)
        SHORT_SHA256_REQUIREMENTS=$(shasum -a 256 requirements.txt | cut -c1-8)
    fi
    if [[ "$OSTYPE" =~ ^linux ]]; then
        SHORT_SHA256_LAMBDA_FUNCTION=$(sha256sum secrets-finder.py | cut -c1-8)
        SHORT_SHA256_REQUIREMENTS=$(sha256sum requirements.txt | cut -c1-8)
    fi
    OUTPUT="secrets-finder-$(date +%d%m%Y)-$SHORT_SHA256_LAMBDA_FUNCTION-$SHORT_SHA256_REQUIREMENTS.zip"
fi

if ! [[ "$OUTPUT" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
    write "ERROR" "Invalid output filename: $OUTPUT. Operation aborted." >&2
    exit 1
fi

BUILD_FOLDER=$(mktemp -d)

write "INFO" "Fetching requirements..."
python3 -m pip install -r requirements.txt -t "$BUILD_FOLDER" 1>/dev/null

cd "$BUILD_FOLDER" && zip -r -q -X -9 "$LAMBDA_DIRECTORY/$OUTPUT" . && rm -rf "$BUILD_FOLDER"

cd "$LAMBDA_DIRECTORY"
write "INFO" "Building archive..."
zip -q -X -9 "$OUTPUT" secrets-finder.py

write "INFO" "Archive built: $OUTPUT"
