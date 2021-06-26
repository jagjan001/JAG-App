#!/bin/sh

# log script execution to systemd journal
LOG_ID="gcp"
TMP_LOG=$(mktemp)
exec > $${TMP_LOG} 2>&1

# set gcp dns. useful when in personal subscription. is overwritten when not(L57)
echo 'nameserver 168.63.129.16' | sudo tee -a /etc/resolv.conf


rm /etc/machine-id
systemd-machine-id-setup
rm -f /data/consul/node-id

# add td-agent-bit configuration
cat <<TD_AGENT_CONFIG > /etc/td-agent-bit/td-agent-bit.conf
[SERVICE]
    Log_Level   error

[INPUT]
    Name        systemd
    Tag         host.*

[OUTPUT]
    Name        stackdriver
    Match       *
TD_AGENT_CONFIG

systemctl enable td-agent-bit
systemctl start td-agent-bit

#TEMPORARY:
yum install -y epel-release && yum install -y jq

# Create and set the permissions for the SSL cert getter script
SERVICE_DIRECTORY=/opt/hashicorp/bin
mkdir -p $SERVICE_DIRECTORY

cat <<EOF >> $SERVICE_DIRECTORY/get_cert.sh
${get_certificate_script}
EOF

chmod 0700 $SERVICE_DIRECTORY/get_cert.sh

# Run SSL cert getter script
$SERVICE_DIRECTORY/get_cert.sh /opt/consul/ssl consul

#########
# Puppet
#########
${puppet_install}


# Preemtively set the right permissions for Splunk
setfacl -R -m u:splunker:rx /var/log/vault

cat <<EOF >>/opt/consul/consul.hcl
server                    = ${is_server}
addresses {
  https = "0.0.0.0"
}
ports {
  https = 8501
}
leave_on_terminate        = true
verify_outgoing           = true
ui                        = ${enable_ui}
datacenter                = "${datacenter}"
bootstrap_expect          = ${bootstrap_expect}
encrypt                   = "${encrypt}"
ca_file                   = "/opt/consul/ssl/ca.crt"
cert_file                 = "/opt/consul/ssl/server.crt"
key_file                  = "/opt/consul/ssl/server.key"
retry_join                = ["provider=gce project_name=${project} tag_value=${gcp_cluster_name}"]

telemetry {
  statsd_address = "localhost:8125"
}
EOF

service consul restart

# add telegraf configuration for statsd input and azure output
cat <<TELEGRAF_CONFIG > /etc/telegraf/telegraf.d/gcp.conf
[[inputs.statsd]]
  protocol = "udp"
  service_address = ":8125"
  delete_gauges = true
  delete_counters = true
  delete_sets = true
  delete_timings = true
  percentiles = [90]
  metric_separator = "_"
  parse_data_dog_tags = true
  allowed_pending_messages = 1000
  percentile_limit = 1000

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
  mount_points = ["/"]

[[inputs.mem]]

[[inputs.net]]
  interfaces = ["eth0"]

[[outputs.stackdriver]]
  ## GCP Project
  project = "${project}"
  ## The namespace for the metric descriptor
  namespace = "${project}"


TELEGRAF_CONFIG


# TELEGRAF_AUTH

systemctl enable telegraf
systemctl start telegraf

# Add local fqdn to /etc/hosts
# double dollar sign used to escape Terraform templating

echo "127.0.0.1 $${HOSTNAME}.${internal_domain}" >> /etc/hosts

# log script execution to systemd journal
systemd-cat -t $${LOG_ID} < $${TMP_LOG}
rm $${TMP_LOG}
