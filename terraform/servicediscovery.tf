resource "aws_service_discovery_private_dns_namespace" "example" {
  name = "example.local"
  vpc  = data.aws_vpc.default.id
}

resource "aws_service_discovery_service" "spring_api" {
  name = "spring-api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.example.id

    dns_records {
      type = "A"
      ttl  = 300
    }
  }
}

resource "aws_service_discovery_service" "node_api" {
  name = "node-api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.example.id

    dns_records {
      type = "A"
      ttl  = 300
    }
  }
}