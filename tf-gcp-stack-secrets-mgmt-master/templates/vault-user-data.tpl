${header}

# TEMPORARY: the image we're using comes with a baked-in nginx; it's removed in Packer already
yum remove -y nginx

# log script execution to systemd journal
LOG_ID="gcp"
TMP_LOG=$(mktemp)
exec > $${TMP_LOG} 2>&1

/opt/hashicorp/bin/get_cert.sh /opt/vault/ssl vault


gcloud iam service-accounts keys create /opt/vault/account.json --iam-account=${service_account}  --project ${project}
export GOOGLE_APPLICATION_CREDENTIALS=/opt/vault/account.json
chown vault:vault /opt/vault/account.json


cat <<VAULT_CONFIG >/opt/vault/vault.hcl
storage "consul" {
  path    = "vault"
  address = "127.0.0.1:8500"
}

listener "tcp" {
    address           = "0.0.0.0:8443"
    tls_disable       = 0
    tls_min_version   = "tls12"
    tls_cert_file     = "/opt/vault/ssl/server.crt"
    tls_key_file      = "/opt/vault/ssl/server.key"
    tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
}

listener "tcp" {
    address           = "0.0.0.0:8200"
    tls_disable       = 0
    tls_min_version   = "tls12"
    tls_cert_file     = "/opt/vault/ssl/server.crt"
    tls_key_file      = "/opt/vault/ssl/server.key"
    tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
}

ui = true

seal "gcpckms" {
  credentials = "/opt/vault/account.json"
  project     = "${project}"
  region      = "global"
  key_ring    = "${keyvault_name}"
  crypto_key  = "${vault_unseal_secret_name}"
}

telemetry {
  statsd_address = "localhost:8125"
}
VAULT_CONFIG

# Restart Vault to get the unseal changes
service vault restart

systemctl restart telegraf

# Splunk config checker

cat <<SPLUNK_CONFIG_CMD > /usr/local/bin/splunk-config
#!/usr/bin/env bash

SPLUNK_APPS="/opt/splunkforwarder/etc/apps/"
AUDIT_DIR="$$(ls $$SPLUNK_APPS | grep hcvault_audit_uf)"
SPLUNK_PATH="$$SPLUNK_APPS$$AUDIT_DIR"

if [ -d "$$SPLUNK_PATH" ]; then
  echo "Splunk configuration successful"
else
  echo "Splunk configuration failed"
fi
SPLUNK_CONFIG_CMD

cat <<SPLUNK_CONFIG_SERVICE > /etc/systemd/system/splunk-config.service
[Unit]
Description=check Splunk configuration

[Service]
Type=oneshot
ExecStart=/usr/local/bin/splunk-config
SPLUNK_CONFIG_SERVICE

cat <<SPLUNK_CONFIG_TIMER > /etc/systemd/system/splunk-config.timer
[Unit]
Description=check Splunk configuration

[Timer]
OnBootSec=15min
OnUnitActiveSec=2h

[Install]
WantedBy=timers.target
SPLUNK_CONFIG_TIMER


systemctl stop firewalld
systemctl disable firewalld
systemctl mask --now firewalld

iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 443 -j REDIRECT --to-ports 8200
iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8200


systemctl enable splunk-config.timer
systemctl start splunk-config.timer

# log script execution to systemd journal
systemd-cat -t $${LOG_ID} < $${TMP_LOG}
rm $${TMP_LOG}
