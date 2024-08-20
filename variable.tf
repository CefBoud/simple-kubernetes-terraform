variable "cluster_domain" {
  type        = string
  description = "base domain for the cluster"
}

variable "zone_name" {
  type        = string
  description = "name of the DNS zone that manages cluster_domain."
}
variable "lets_encrypt_notification_inbox" {
  type        = string
  description = "Email address to receive letsencrypt notification."
}

variable "opensearch_password" {
  type        = string
  default     = "myStrongPassword123@456" # TODO: generate this using random_password tf resource
  description = "Opensearch admin password."
}

