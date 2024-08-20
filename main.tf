

resource "google_compute_subnetwork" "foo" {
  name          = "foo-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.foo.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

resource "google_compute_network" "foo" {
  name                    = "foo-network"
  auto_create_subnetworks = false
}

resource "google_container_cluster" "foo" {
  name     = "my-gke-cluster"
  location = "us-central1"

  network             = google_compute_network.foo.id
  subnetwork          = google_compute_subnetwork.foo.id
  deletion_protection = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-ranges"
    services_secondary_range_name = google_compute_subnetwork.foo.secondary_ip_range.0.range_name
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  location   = "us-central1" # chose a region instead of zone to get multiple masters across different zones
  cluster    = google_container_cluster.foo.name
  node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  node_config {
    # preemptible  = true
    machine_type = "e2-standard-2" #"e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    # service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    disk_size_gb = 50

  }

}
