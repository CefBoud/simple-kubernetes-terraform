# Terraform GKE Kubernetes Cluster Deployment

This repository contains Terraform code to deploy a Kubernetes cluster on Google Cloud Platform (GCP) using Google Kubernetes Engine (GKE). The cluster is configured with an Nginx Ingress controller and automatic TLS certificate generation via cert-manager.

The primary purpose of this code is to provide a simple, yet functional example of a Kubernetes cluster deployment. It can serve as a starting point for your own projects.

## Prerequisites

Before getting started, ensure you have the following:

- A Google Cloud Platform (GCP) account.
- A GCP Service Account with sufficient permissions to manage resources (IAM, GKE, DNS, etc.), along with its key file for authentication.
- A GCP-managed DNS Zone i.e. a domain name managed by GCP and pointing to its nameservers.
- Supply Terraform variables as environment variables and as a tfvars file :

```
cluster_domain                  = "mydomain.com"
zone_name                       = "mydomain-zone-name-in-gcp"
lets_encrypt_notification_inbox = "jd@email.com"

```

## Getting Started

1. Clone this repository and navigate to its root directory.
2. Ensure all prerequisites are met.
3. Initialize Terraform, review the planned changes, and apply the configuration:

   ```bash
   terraform init
   terraform plan
   terraform apply 
   ```

## Accessing Deployed Services

- **OpenSearch**: Access OpenSearch using the following command:

  ```bash
  curl -k -u "admin:myStrongPassword123@456" https://opensearch.<cluster_domain>
  ```

- **Fluentbit** forwards containers logs to Opensearch. We can query them using:

    ```
    export cluster_domain=<cluster_domain>
    curl -k -u "admin:myStrongPassword123@456" "https://opensearch.${cluster_domain}/fluent-bit-logs/_search" -H 'Content-Type: application/json' -d'
    {
    "query": {
        "match": {
        "message": "error"
        }
    }
    }' | jq
    ```

- **Grafana**: Grafana's credentials are `admin:prom-operator`. It is accessible at:

  ```bash
  https://grafana.<cluster_domain>
  ```


  The TLS certificate are automatically generated and signed by Let's Encrypt.

## Cleanup

To destroy the Kubernetes cluster and all associated resources, run:

```bash
terraform destroy
```
