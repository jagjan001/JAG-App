#!/bin/sh

# log script execution to systemd journal
LOG_ID="gcp"
TMP_LOG=$(mktemp)
exec > $${TMP_LOG} 2>&1

gcloud iam service-accounts keys delete $(cat /home/consul/account.json | jq .private_key_id -r) --iam-account=${service_account}  --project=${project} --quiet

systemd-cat -t $${LOG_ID} < $${TMP_LOG}
rm $${TMP_LOG}
