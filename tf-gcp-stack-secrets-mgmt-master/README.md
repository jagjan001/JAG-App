# tf-gcp-stack-secrets-mgmt

## Prerequisites

### __Request GCP Owner Access__
To execute KMS and IAM you need to request for GCP Owner Execption. [Follow this document to open ticket with Cloud Operation Support.](https://docs.google.com/document/d/13RslpUkoao6Asipz3bLtZn-h6m4OsRgwxmNmyRse-wE/edit)

### __Enabling GCP Identity and Access Management (IAM) API__
This API needed to be enable in order for VMs to discover/talk with GCP services in the project.

Steps to enable IAM API:
1. Go to GCP API Library:   `https://console.cloud.google.com/apis/library?q=IAM`
2. Click on API name: `Identity and Access Management (IAM) API`. Confirm the `Service Name` is `iam.googleapis.com`
3. Click on `Enable API`


### __Create KMS Keyring & IAM Role__
We need to create Keyring and IAM Role before we can deploy the whole stack. 

Note: _Once the Keyring is created it cannot be deleted this is GCP policy._
```
$ cd kms-iam/
$ terraform init
$ terraform plan -var-file kms-iam.tfvars
$ terraform apply -var-file kms-iam.tfvars
```

## Deploy
### __Deploying Vault Stack__
