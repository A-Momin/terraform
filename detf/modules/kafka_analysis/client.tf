provider "kafka" {
  bootstrap_servers = aws_msk_cluster.kafka.bootstrap_brokers_tls
  tls {
    ca_cert = file("${path.module}/certs/ca.pem")
  }
  sasl {
    mechanism = "AWS_MSK_IAM"
    iam       = true
  }
}

resource "kafka_topic" "events" {
  name               = "events"
  partitions         = 6
  replication_factor = 3
  config = {
    "retention.ms" = "604800000"
  }
}
