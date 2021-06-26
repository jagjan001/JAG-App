#!/bin/bash -x

LOG_ID="gcp"
TMP_LOG=$(mktemp)
exec > $${TMP_LOG} 2>&1

SSL_PATH=\$1
USERNAME=\$2
SERVER_NAME=\$(hostname)

# Ensure the SSL directory exists and has proper permissions
mkdir -p \$SSL_PATH
chown \$USERNAME.\$USERNAME \$SSL_PATH
chmod 0700 \$SSL_PATH

# SNOW CERTIFICATE AUTOMATION SCRIPT
SNOW_ENDPOINT="${snow_url}"
PRIMARYOWNER="${snow_email_primary}"
SECONDARYOWNER="${snow_email_secondary}"
DEPTLOS="${deptlos}"
TERRITORY="${territory}"
APPTEAM="${appteam}" 

COUNTRY="${conf_country}"
STATE="${conf_state}"
LOCALITY="${conf_locality}"
ORG="${conf_org}"
ORGUNIT="${conf_orgunit}"
CN="${internal_domain}"
SAN_NAME="${san_name}"

# Headers
SNOW_AUTH="${snow_auth}"
API_KEY="${api_key}"
API_SECRET="${api_secret}"
IDAM_AUTH="${idam_auth}"

if [ -z "\$SNOW_AUTH" ];
then 
  exit 1
fi
if [ -z "\$API_KEY" ]; 
then
  exit 1
fi
if [ -z "\$API_SECRET" ];
then
  exit 1
fi
if [ -z "\$IDAM_AUTH" ];
then
  exit 1
fi

# Generate CSR configuration file
cat > \$SSL_PATH/server.conf <<HEREDOC
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C=\$COUNTRY
ST=\$STATE
L=\$LOCALITY
O=\$ORG
OU=\$ORGUNIT
CN=\$CN

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = \$SAN_NAME
IP.1 = 127.0.0.1
HEREDOC

# Generate private key with the default values (4096 bits, RSA)
openssl req -new -newkey rsa:2048 -nodes -keyout \$SSL_PATH/server.key -out tmp_csr_req_file -config \$SSL_PATH/server.conf

BASE64=\$(cat tmp_csr_req_file | tr -d '\n')

# Submit CSR request
cat > csr_request.json <<HEREDOC
{
  "primaryowner": "\$PRIMARYOWNER",
  "secondaryowner": "\$SECONDARYOWNER",
  "departmentlos": "\$DEPTLOS",
  "territory": "\$TERRITORY",
  "applicationteam": "\$APPTEAM",
  "base64": "\$BASE64"
}
HEREDOC

SYS_ID=\$(curl -s -X POST -d@csr_request.json -H "Content-Type: application/json" -H "Authorization: Basic \$SNOW_AUTH" -H "apikey: \$API_KEY" -H "apikeysecret: \$API_SECRET" -H "Proxy-Authorization: Basic \$IDAM_AUTH" \$SNOW_ENDPOINT/pwcnetwork/service_now/api/pglsc/pwc_internal_certificate_request/submit_request | jq -r '.result.sysid')

# Check status of snow request
STATUS=1
ATTEMPTS=0
until [[ "\$STATUS" -eq "3" || "\$STATUS" -eq "4" ]] || [[ "\$ATTEMPTS" -eq "10" ]]
do
  STATUS=\$(curl -s -X Get -H "Content-Type: application/json" -H "Authorization: Basic \$SNOW_AUTH" -H "apikey: \$API_KEY" -H "apikeysecret: \$API_SECRET" -H "Proxy-Authorization: Basic \$IDAM_AUTH" \$SNOW_ENDPOINT/pwcnetwork/service_now/api/now/table/sc_req_item?sysparm_query=sys_id=\$SYS_ID | jq -r '.result[0].state')
  sleep 10
  let ATTEMPTS=ATTEMPTS+1
done 

# Get download URL
curl -o prod_download_link.json -H "Accept: application/json" -H "Authorization: Basic \$SNOW_AUTH" -H "apikey: \$API_KEY" -H "apikeysecret: \$API_SECRET" -H "Proxy-Authorization: Basic \$IDAM_AUTH" \$SNOW_ENDPOINT/pwcnetwork/service_now/api/now/attachment?sysparm_query=table=sc_task%5Etable_sys_id=\$SYS_ID

DOWNLOAD_LINK=\$(cat prod_download_link.json | jq -r '.result[0].download_link')

# Download certificate
curl -o \$SSL_PATH/server.crt -H "Accept: application/json" -H "Authorization: Basic \$SNOW_AUTH" -H "apikey: \$API_KEY" -H "apikeysecret: \$API_SECRET" -H "Proxy-Authorization: Basic \$IDAM_AUTH" \$DOWNLOAD_LINK

# Create serial file
openssl x509 -in \$SSL_PATH/server.crt -serial -noout >> \$SSL_PATH/serial.txt

# Copy over ca.crt
cat <<HEREDOC > \$SSL_PATH/ca.crt
${public_ca}
HEREDOC

chown \$USERNAME.\$USERNAME \$SSL_PATH/{ca.crt,server.crt,server.key,serial.txt}
chmod 0600 \$SSL_PATH/server.key

cp \$SSL_PATH/ca.crt /etc/pki/ca-trust/source/anchors/ && update-ca-trust

systemd-cat -t $${LOG_ID} < $${TMP_LOG}
