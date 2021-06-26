#!/bin/bash

set -e

# adding the repos statically because the 
# installation scripts were failing in Packer

# install Stackdriver Monitoring
# https://cloud.google.com/monitoring/agent/install-agent

cat <<EOF > /etc/yum.repos.d/google-cloud-monitoring.repo
[google-cloud-monitoring]
name=Google Cloud Monitoring Agent Repository
baseurl=https://packages.cloud.google.com/yum/repos/google-cloud-monitoring-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# install Stackdriver Logging
# https://cloud.google.com/logging/docs/agent/installation

cat <<EOF > /etc/yum.repos.d/google-cloud-logging.repo
[google-cloud-logging]
name=Google Cloud Logging Agent Repository
baseurl=https://packages.cloud.google.com/yum/repos/google-cloud-logging-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo yum install -y google-fluentd stackdriver-agent

# Pull Vault data from syslog into a file for fluentd
cat <<EOF > /etc/rsyslog.d/vault.conf
#
# Extract Vault logs from syslog
#

# Only include the message (Vault has its own timestamps and data)
template(name="OnlyMsg" type="string" string="%msg:2:$:drop-last-lf%\n")

if ( $programname == "vault" ) then {
  action(type="omfile" file="/var/log/vault/server.log" template="OnlyMsg")
  stop
}
EOF

# Start Stackdriver logging agent and setup the filesystem to be ready to
# receive audit logs
mkdir -p /etc/google-fluentd/config.d/

cat <<EOF > /etc/google-fluentd/config.d/vaultproject.io.conf
<source>
  @type tail
  format json

  time_type "string"
  time_format "%Y-%m-%dT%H:%M:%S.%N%z"
  keep_time_key true

  path /var/log/vault/audit.log
  pos_file /var/lib/google-fluentd/pos/vault.audit.pos
  read_from_head true
  tag vaultproject.io/audit
</source>

<filter vaultproject.io/audit>
  @type record_transformer
  enable_ruby true
  <record>
    message "$${record.dig('request', 'id') || '-'} $${record.dig('request', 'remote_address') || '-'} $${record.dig('auth', 'display_name') || '-'} $${record.dig('request', 'operation') || '-'} $${record.dig('request', 'path') || '-'}"
    host "#{Socket.gethostname}"
  </record>
</filter>

<source>
  @type tail
  format /^(?<time>[^ ]+) \[(?<severity>[^ ]+)\][ ]+(?<source>[^:]+): (?<message>.*)/

  time_type "string"
  time_format "%Y-%m-%dT%H:%M:%S.%N%z"
  keep_time_key true

  path /var/log/vault/server.log
  pos_file /var/lib/google-fluentd/pos/vault.server.pos
  read_from_head true
  tag vaultproject.io/server
</source>

<filter vaultproject.io/server>
  @type record_transformer
  enable_ruby true
  <record>
    message "$${record['source']}: $${record['message']}"
    severity "$${(record['severity'] || '').downcase}"
    host "#{Socket.gethostname}"
  </record>
</filter>
EOF

#statsd collector
mkdir -p /opt/stackdriver/collectd/etc/collectd.d

cat <<EOF > /opt/stackdriver/collectd/etc/collectd.d/statsd.conf
# This is the monitoring configuration for StatsD.
LoadPlugin statsd

<Plugin statsd>
  Host "127.0.0.1"
  Port "8125"
  DeleteSets true
  TimerPercentile 50.0
  TimerPercentile 95.0
  TimerLower true
  TimerUpper true
  TimerSum true
  TimerCount true
</Plugin>

LoadPlugin match_regex
LoadPlugin target_set
LoadPlugin target_replace

PreCacheChain "PreCache"
<Chain "PreCache">
  <Rule "rewrite_statsd">
    <Match regex>
      Plugin "^statsd$"
    </Match>
    <Target "set">
      MetaData "stackdriver_metric_type" "custom.googleapis.com/statsd/%{type}"
      MetaData "label:metric" "%{type_instance}"
    </Target>
  </Rule>
</Chain>
EOF
