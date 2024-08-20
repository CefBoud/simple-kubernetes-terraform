
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.41"
    }
    helm = {
      source  = "helm"
      version = "~> 2.15.0"
    }

    kubernetes = {
      source  = "kubernetes"
      version = "~> 2.32.0 "
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "google" {
  credentials = file("gcp-service-account-key.json")
  project     = "solar-botany-432821-v1"
  region      = "us-central1"
}

# Retrieve an access token
data "google_client_config" "provider" {}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.foo.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.foo.master_auth[0].cluster_ca_certificate,
    )
  }
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.foo.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.foo.master_auth[0].cluster_ca_certificate,
  )
}

provider "kubectl" {
  host  = "https://${google_container_cluster.foo.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.foo.master_auth[0].cluster_ca_certificate,
  )
}

