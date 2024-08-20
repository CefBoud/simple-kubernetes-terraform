
locals {
  prometheus_stack_chart_version = "61.7.2"
  ingress_nginx_chart_version    = "4.11.2"
  cert_manager_chart_version     = "1.15.3"
  opensearch_chart_version       = "2.22.1"
  fluentbit_chart_version        = "0.43.0"
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = local.ingress_nginx_chart_version
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    templatefile("${path.module}/templates/nginx-values.yml", {
      cluster_domain = var.cluster_domain
    })
  ]

}

data "google_dns_managed_zone" "foo" {
  name = var.zone_name
}

data "kubernetes_service" "nginx_load_balancer" {
  depends_on = [helm_release.ingress_nginx]
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}
resource "google_dns_record_set" "grafana_record" {
  name         = "grafana.${var.cluster_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.foo.name
  rrdatas      = [data.kubernetes_service.nginx_load_balancer.status[0].load_balancer[0].ingress[0].ip]
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = local.cert_manager_chart_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# Using kubectl instead of kubernetes provider to avoid the issue:
# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "kubectl_manifest" "cert_manager" {
  depends_on = [helm_release.cert_manager]
  yaml_body = templatefile("${path.module}/templates/cert-manager-letsencrypt.yml", {
    namespace          = kubernetes_namespace.cert_manager.metadata[0].name
    notification_email = var.lets_encrypt_notification_inbox
  })
}


resource "kubernetes_namespace" "prometheus_stack" {
  metadata {
    name = "prometheus-stack"
  }
}

resource "helm_release" "prometheus_stack" {

  depends_on = [google_dns_record_set.grafana_record, helm_release.cert_manager]
  name       = "prom-grafana"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = local.prometheus_stack_chart_version
  namespace  = kubernetes_namespace.prometheus_stack.metadata[0].name

  values = [
    templatefile("${path.module}/templates/prom-stack-values.yml", {
      cluster_domain = var.cluster_domain
    })
  ]

}

resource "google_dns_record_set" "opensearch" {
  name         = "opensearch.${var.cluster_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.foo.name
  rrdatas      = [data.kubernetes_service.nginx_load_balancer.status[0].load_balancer[0].ingress[0].ip]
}

resource "kubernetes_namespace" "opensearch" {
  metadata {
    name = "opensearch"
  }
}

resource "helm_release" "opensearch" {

  depends_on = [google_dns_record_set.opensearch, helm_release.cert_manager]
  name       = "opensearch"

  repository = "https://opensearch-project.github.io/helm-charts"
  chart      = "opensearch"
  version    = local.opensearch_chart_version
  namespace  = kubernetes_namespace.opensearch.metadata[0].name

  values = [
    templatefile("${path.module}/templates/opensearch-values.yml", {
      cluster_domain      = var.cluster_domain
      opensearch_password = var.opensearch_password
    })
  ]

}

resource "kubernetes_namespace" "fluentbit" {
  metadata {
    name = "fluentbit"
  }
}

resource "helm_release" "fluentbit" {
  depends_on = [helm_release.opensearch]
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = local.fluentbit_chart_version
  namespace  = kubernetes_namespace.fluentbit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/fluentbit-values.yml", {
      opensearch_password = var.opensearch_password
    })
  ]

}

