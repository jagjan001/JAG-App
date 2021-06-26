#!/bin/bash

# Execution Example:
#   <set vault addr>                  <script name>      <encrypted root token> <ttl>
# $ VAULT_ADDR=https://127.0.0.1:8200 ./pwc_vault_init.sh ./encrypted_root.txt 72h 

ENC_TOKEN_FILE=$1
TTL="${2:-24h}"

# Ensure encrypted, base64 encoded token file is passed
if [ "$ENC_TOKEN_FILE" == "" ]; then
  echo 'Error: set the file containing the encrypted token.' >&2
  exit 1
fi

# Ensure tools are installed
for app in vault gpg base64; do
  if ! [ -x "$(command -v $app)" ]; then
    echo "Error: $app is not installed." >&2
    exit 1
  fi
done

# Ensure VAULT_ADDR is set
if [ -v "$VAULT_ADDR" ]; then
  echo 'Error: please set the VAULT_ADDR.' >&2
  exit 1
fi

# Decode and decrypt token using gpg keyring
if [ "$(uname -s)" == "Darwin" ]; then
 ROOT_TOKEN=$(base64 -D < "$ENC_TOKEN_FILE" | gpg -d)
else
 ROOT_TOKEN=$(base64 -d < "$ENC_TOKEN_FILE" | gpg -d)
fi
export ROOT_TOKEN

# Create root-like token
export VAULT_TOKEN=$ROOT_TOKEN
VAULT_TOKEN=$(vault token create -policy=root -ttl="$TTL" -field=token -orphan -renewable)
export VAULT_TOKEN
# Enable audit log
vault audit enable file file_path=/var/log/vault/vault_audit.log

# Enable vault system configurations
vault write sys/config/ui/headers/Strict-Transport-Security values="max-age=31536000; includeSubDomains"
vault write sys/config/ui/headers/X-XSS-Protection values="1; mode=block"
vault write sys/config/ui/headers/X-Content-Type values="nosniff"
vault write sys/config/ui/headers/X-Frame-Options values="SAMEORIGIN"

vault token revoke "$ROOT_TOKEN"
