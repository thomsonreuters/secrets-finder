#!/bin/bash
if echo "$1" | grep -iq "username"; then
  echo "$SECRETS_FINDER_SCAN_USERNAME"
elif echo "$1" | grep -iq "password"; then
  echo "$SECRETS_FINDER_SCAN_TOKEN"
fi
