data "aws_service_discovery_dns_namespace" "test" {
  count = var.cluster_cloudmap_namespace_name != null ? 1 : 0
  name  = var.cluster_cloudmap_namespace_name #"${var.owner}.${var.environment}.cluster"
  type  = "DNS_PRIVATE"
}

resource "aws_service_discovery_service" "service" {
  count = var.cluster_cloudmap_namespace_name != null ? 1 : 0
  name  = var.app

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.test[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}