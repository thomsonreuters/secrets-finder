#!/bin/bash

function write {
  printf "%-10s %s\n" "[$1]" "$2"
}

function show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --decrypt-private-key    Decrypt the private key in private_key_insecure.pem (warning: the file will remain on disk)"
  echo "  --force-replacement      Force the replacement of existing files (private_key.pem, private_key_insecure.pem, cert.pem, ca_chain.pem)"
  echo "  --help                   Display this help and exit"
  echo ""
  echo "Environment variables:"
  echo "  SECRETS_FINDER_CERTIFICATE_FILE      Path to the PKCS12 certificate file"
  echo "  SECRETS_FINDER_CERTIFICATE_PASSWORD  Password of the PKCS12 certificate file"
}

echo "****************************************"
echo "*   Extraction of PKCS12 certificate   *"
echo "****************************************"
if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux-gnu"* ]]; then
  write "ERROR" "Unsupported operating system ($OSTYPE). Only macOS and Linux operating systems are supported."
  exit 1
fi

DECRYPT_PRIVATE_KEY=false
FORCE_REPLACEMENT=false

for arg in "$@"; do
  case $arg in
  --decrypt-private-key)
    DECRYPT_PRIVATE_KEY=true
    shift
    ;;
  --force-replacement)
    FORCE_REPLACEMENT=true
    shift
    ;;
  --help)
    show_help
    exit 0
    ;;
  esac
done

if ! command -v openssl &>/dev/null; then
  write "ERROR" "openssl could not be found"
  exit 1
fi

if [ -z "$SECRETS_FINDER_CERTIFICATE_FILE" ]; then
  write "ERROR" "Environment variable missing (SECRETS_FINDER_CERTIFICATE_FILE). Specify the path to the PKCS12 certificate file and try again."
  exit 1
fi

if [ -z "$SECRETS_FINDER_CERTIFICATE_PASSWORD" ]; then
  write "ERROR" "Environment variable missing (SECRETS_FINDER_CERTIFICATE_PASSWORD). Specify the password of the PKCS12 certificate file and try again."
  exit 1
fi

write "INFO" "Certificate: $SECRETS_FINDER_CERTIFICATE_FILE"

if [ -f private_key.pem ] || [ -f private_key_insecure.pem ] || [ -f cert.pem ] || [ -f ca_chain.pem ]; then
  if [ "$FORCE_REPLACEMENT" = false ]; then
    write "ERROR" "One or more of the following files already exist: private_key.pem, private_key_insecure.pem, cert.pem, ca_chain.pem"
    exit 1
  else
    write "WARNING" "One or more of the following files already exist and will be replaced: private_key.pem, private_key_insecure.pem, cert.pem, ca_chain.pem"
  fi
fi

if openssl pkcs12 -in "$SECRETS_FINDER_CERTIFICATE_FILE" -nocerts -out private_key.pem --passin pass:"$SECRETS_FINDER_CERTIFICATE_PASSWORD" --passout pass:"$SECRETS_FINDER_CERTIFICATE_PASSWORD" &>/dev/null; then
  write "INFO" "Private key extracted successfully"
else
  write "ERROR" "Private key extraction failed"
  exit 1
fi

if [ "$DECRYPT_PRIVATE_KEY" = true ]; then
  if openssl rsa -in private_key.pem -out private_key_insecure.pem --passin pass:"$SECRETS_FINDER_CERTIFICATE_PASSWORD" &>/dev/null; then
    write "INFO" "Private key decrypted successfully"
    write "WARNING" "private_key_insecure.pem is not encrypted"
  else
    write "ERROR" "Private key decryption failed"
    exit 1
  fi
else
  write "INFO" "Private key not decrypted (--decrypt-private-key not specified)"
fi

if openssl pkcs12 -in "$SECRETS_FINDER_CERTIFICATE_FILE" -clcerts -nokeys -out cert.pem --passin pass:"$SECRETS_FINDER_CERTIFICATE_PASSWORD" &>/dev/null; then
  write "INFO" "Certificate extracted successfully"
else
  write "ERROR" "Certificate extraction failed"
  exit 1
fi

if openssl pkcs12 -in "$SECRETS_FINDER_CERTIFICATE_FILE" -cacerts -nokeys -chain -out ca_chain.pem --passin pass:"$SECRETS_FINDER_CERTIFICATE_PASSWORD" &>/dev/null; then
  write "INFO" "CA chain extracted successfully"
else
  write "ERROR" "CA chain extraction failed"
  exit 1
fi

write "INFO" "All files were extracted successfully"
