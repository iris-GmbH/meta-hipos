#!/bin/sh

set -eu

# get directory of script file
if [ -f "$0" ]; then script=$0; else script=$(command -v -- "$0"); fi
dir=$(dirname -- "$script")

PRIVATE_KEY="${dir}/ssh_pam_snakeoil.key"

# create tmp file for message
tmp=$(mktemp /dev/shm/sign.XXXXXX)
trap 'rm -f "$tmp"' EXIT

# decode, sign, encode and output
base64 -d > "${tmp}"
output=$(openssl pkeyutl -sign -rawin -in "${tmp}" -inkey "${PRIVATE_KEY}" | base64 -w0)
echo "vault:v1:${output}"
