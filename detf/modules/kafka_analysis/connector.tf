resource "aws_iam_role" "mskconnect_role" {
  name               = "mskconnect-role"
  assume_role_policy = data.aws_iam_policy_document.mskconnect_assume.json
}

resource "aws_mskconnect_connector" "s3_sink" {
  name                 = "s3-sink-connector"
  kafkaconnect_version = "2.7.1"

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.kafka.bootstrap_brokers
      vpc {
        subnets         = module.vpc.private_subnet_ids
        security_groups = [aws_security_group.mskconnect_sg.id]
      }
    }
  }

  capacity {
    autoscaling {
      max_worker_count = 3
      min_worker_count = 1
    }
  }

  connector_configuration = {
    "connector.class" = "io.confluent.connect.s3.S3SinkConnector"
    "tasks.max"       = "1"
    "topics"          = "topic1,topic2"
    "s3.bucket.name"  = aws_s3_bucket.sink_bucket.id
    # other connector props...
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    enabled = true
  }

  service_execution_role_arn = aws_iam_role.mskconnect_role.arn

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.example.arn
      revision = aws_mskconnect_custom_plugin.example.latest_revision
    }
  }
}
