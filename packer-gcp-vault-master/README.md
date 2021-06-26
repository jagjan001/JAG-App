# packer-gcp-vault
This repo builds the VM image for the Vault service in GCP.

# Authenticate with GCP
```
gcloud auth application-default login
```
Once you are sucessfully authenticated set the `GOOGLE_APPLICATION_CREDENTIALS` enviroment variable. 

```
# On Windows, this is:
%APPDATA%/gcloud/application_default_credentials.json

# On other systems:
$HOME/.config/gcloud/application_default_credentials.json

## For Example:
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json

```


# Variables
As part of this build you’ll need to create a variables.json file. Below we have an explanation of all variables used, their defaults.


|Variable Name|Description|Default|
|-------------| --------- |-------|
|project_id  | GCP project ID| |
|zone        | GCP zone where instance for build will spin up e.g. `us-east4-a` | |
|subnetwork  | GCP VPC name where build instance will launch e.g. `default` ||
|vault_download_url| Vault Binary URL | gs://hashicorp-enterprise-binaries/vault/1.2.4/vault-enterprise_1.2.4+prem_linux_amd64.zip|
|consul_download_url| Consul Binary URL | gs://hashicorp-enterprise-binaries/consul/1.6.2/consul-enterprise_1.6.2+prem_linux_amd64.zip|
|tags| GCP network tag | default-ssh


Content of the variables.json file
```
{
    "project_id": "",
    "zone": "",
    "subnetwork": "default"
}
```


# Build
Building both vault and consul images
```
packer build -var-file=variables.json build.json
```

Building Indivdual Image:

```
packer build -only="Consul Image" -var-file=variables.json build.json
```
```
packer build -only="Vault Image" -var-file=variables.json build.json
```


