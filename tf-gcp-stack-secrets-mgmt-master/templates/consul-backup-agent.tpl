
tee /etc/yum.repos.d/gcsfuse.repo > /dev/null <<EOF
[gcsfuse]
name=gcsfuse (packages.cloud.google.com)
baseurl=https://packages.cloud.google.com/yum/repos/gcsfuse-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum update -y
yum install gcsfuse -y
gcloud auth login

mkdir -p /opt/consul/backups
chown consul.consul /opt/consul/backups

gcloud iam service-accounts keys create /home/consul/account.json --iam-account=${service_account}  --project ${project}
export GOOGLE_APPLICATION_CREDENTIALS=/home/consul/account.json
chown vault:vault /home/consul/account.json



#gcsfuse ${cloud_storage_bucket} /opt/consul/backups
#mount -t gcsfuse -o rw,user ${cloud_storage_bucket} /opt/consul/backups


cat <<AGENT >/usr/lib/systemd/system/consul-backup-agent.service
[Unit]
Description="HashiCorp Consul Backup Agent"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/opt/consul/backup_agent.json

[Service]
User=consul
Group=consul
ExecStart=/bin/consul snapshot agent -config-file=/opt/consul/backup_agent.json
KillMode=process
Restart=on-failure
RestartSec=60
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
AGENT

cat <<SNAPSHOT >/opt/consul/backup_agent.json
{
  "snapshot_agent": {
    "http_addr": "127.0.0.1:8500",
    "datacenter": "${datacenter}",
    "ca_file": "/opt/consul/ssl/ca.crt",
    "cert_file": "/opt/consul/ssl/server.crt",
    "key_file": "/opt/consul/ssl/server.key",
    "log": {
      "level": "INFO",
      "enable_syslog": true
    },
    "snapshot": {
      "interval": "1h",
      "retain": 30,
      "stale": false,
      "service": "consul-snapshot",
      "deregister_after": "72h",
      "lock_key": "consul-snapshot/lock",
      "max_failures": 3
    },
    "local_storage": {
      "path": "/opt/consul/backups"
    },
    "google_storage": {
      "bucket": "${cloud_storage_bucket}"
    }
  }
}
SNAPSHOT

systemctl daemon-reload
systemctl enable consul-backup-agent
systemctl start consul-backup-agent
