
output "kubernetes_cluster_name" {
  value = google_container_cluster.foo.name
}

output "kubernetes_cluster_endpoint" {
  value = google_container_cluster.foo.endpoint
}
