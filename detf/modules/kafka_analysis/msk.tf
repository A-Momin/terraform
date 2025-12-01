resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK encryption"
  deletion_window_in_days = 30
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = "prod-msk-cluster"
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = module.vpc.private_subnet_ids
    security_groups = [aws_security_group.msk_sg.id]
    storage_info {
      ebs_storage_info {
        volume_size = 500
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      in_cluster    = true
      client_broker = "TLS"
    }
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
  }

  client_authentication {
    sasl {
      iam   = true
      scram = true # optional: enable SCRAM
    }
    tls {
      enabled = true
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = false
      }
    }
  }

  enhanced_monitoring = "PER_TOPIC_PER_PARTITION"
}
