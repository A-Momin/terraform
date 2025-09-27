# # This script is generated from ChatGPT and enhanced for production use.
# # It's not tested. Review and adjust as needed.

# ############################################
# # Variables (tune for your environment)
# ############################################
# variable "project" {
#   type    = string
#   default = "payments"
# }

# variable "environment" {
#   type    = string
#   default = "prod"
# }

# variable "primary_region" {
#   type    = string
#   default = "us-east-1"
# }

# # Leave empty [] if you don't want a Global Table
# variable "replica_regions" {
#   type    = list(string)
#   default = ["us-west-2"]
# }

# # Initial provisioned capacity (auto scaling will manage thereafter)
# variable "rcu_min" {
#   type    = number
#   default = 5
# }

# variable "rcu_max" {
#   type    = number
#   default = 1000
# }

# variable "wcu_min" {
#   type    = number
#   default = 5
# }

# variable "wcu_max" {
#   type    = number
#   default = 1000
# }

# variable "target_utilization_percent" {
#   type    = number
#   default = 70
# }

# # GSI autoscaling limits (example for one GSI)
# variable "gsi_rcu_min" {
#   type    = number
#   default = 5
# }

# variable "gsi_rcu_max" {
#   type    = number
#   default = 500
# }

# variable "gsi_wcu_min" {
#   type    = number
#   default = 5
# }

# variable "gsi_wcu_max" {
#   type    = number
#   default = 500
# }

# ############################################
# # DynamoDB Table (Production-grade)
# ############################################
# resource "aws_dynamodb_table" "this" {
#   name           = "${var.project}-${var.environment}"
#   billing_mode   = "PROVISIONED" # PROVISIONED (required for autoscaling). Use PAY_PER_REQUEST if you want on-demand.
#   read_capacity  = max(var.rcu_min, 1)
#   write_capacity = max(var.wcu_min, 1)

#   # Primary key (composite so we can demonstrate LSI support)
#   hash_key  = "pk"
#   range_key = "sk"

#   # Attributes used by PK/SK and indexes
#   attribute {
#     name = "pk"
#     type = "S"
#   }
#   attribute {
#     name = "sk"
#     type = "S"
#   }
#   attribute {
#     name = "lsi1_sk" # LSI sort key
#     type = "S"
#   }
#   attribute {
#     name = "gsi1_pk"
#     type = "S"
#   }
#   attribute {
#     name = "gsi1_sk"
#     type = "S"
#   }

#   ##########################################
#   # Local Secondary Index (requires range_key on table)
#   ##########################################
#   local_secondary_index {
#     name               = "lsi1"
#     range_key          = "lsi1_sk"
#     projection_type    = "INCLUDE" # KEYS_ONLY | INCLUDE | ALL
#     non_key_attributes = ["some_attr", "another_attr"]
#   }

#   ##########################################
#   # Global Secondary Index (example)
#   ##########################################
#   global_secondary_index {
#     name            = "gsi1"
#     hash_key        = "gsi1_pk"
#     range_key       = "gsi1_sk"
#     projection_type = "ALL"
#     read_capacity   = max(var.gsi_rcu_min, 1)
#     write_capacity  = max(var.gsi_wcu_min, 1)
#   }

#   ##########################################
#   # Streams (enable for CDC, Lambda triggers, etc.)
#   ##########################################
#   stream_enabled   = true
#   stream_view_type = "NEW_AND_OLD_IMAGES" # KEYS_ONLY | NEW_IMAGE | OLD_IMAGE | NEW_AND_OLD_IMAGES

#   ##########################################
#   # TTL (store epoch seconds in this attribute)
#   ##########################################
#   ttl {
#     attribute_name = "ttl"
#     enabled        = true
#   }

#   ##########################################
#   # Server-Side Encryption (SSE with AWS-managed KMS key)
#   # For CMK, set sse_type = "KMS" and provide kms_key_arn.
#   ##########################################
#   sse_specification {
#     enabled  = true
#     sse_type = "KMS" # KMS or AES256. With KMS and no key ARN, AWS-owned key is used.
#     # kms_key_arn = aws_kms_key.dynamodb.arn
#   }

#   ##########################################
#   # Point-in-Time Recovery (PITR)
#   ##########################################
#   point_in_time_recovery {
#     enabled = true
#   }

#   ##########################################
#   # Contributor Insights (recommended)
#   ##########################################
#   contributor_insights_enabled = true

#   ##########################################
#   # Table Class & Deletion Protection
#   ##########################################
#   table_class                 = "STANDARD" # STANDARD | STANDARD_INFREQUENT_ACCESS
#   deletion_protection_enabled = true       # Protect against accidental deletes

#   ##########################################
#   # Global Table (v2) — optional replicas
#   ##########################################
#   dynamic "replica" {
#     for_each = var.replica_regions
#     content {
#       region_name = replica.value
#       # Optional per-replica settings (uncomment as needed):
#       # point_in_time_recovery {
#       #   enabled = true
#       # }
#       # kms_key_arn = "arn:aws:kms:${replica.value}:...:key/..."   # if using CMK per region
#     }
#   }

#   ##########################################
#   # Tags
#   ##########################################
#   tags = {
#     Project     = var.project
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     CostCenter  = "finops-1234"
#     DataClass   = "confidential"
#   }

#   ##########################################
#   # Safety (common in prod)
#   ##########################################
#   lifecycle {
#     prevent_destroy = true
#     ignore_changes = [
#       # Allow autoscaling to adjust provisioned capacity without forcing diffs
#       read_capacity,
#       write_capacity,
#       global_secondary_index,
#     ]
#   }
# }

# ############################################
# # Application Auto Scaling (Table RCUs/WCUs)
# ############################################

# # READ capacity target
# resource "aws_appautoscaling_target" "table_read" {
#   max_capacity       = var.rcu_max
#   min_capacity       = var.rcu_min
#   resource_id        = "table/${aws_dynamodb_table.this.name}"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "table_read_policy" {
#   name               = "${aws_dynamodb_table.this.name}-rcu-target"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.table_read.resource_id
#   scalable_dimension = aws_appautoscaling_target.table_read.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.table_read.service_namespace

#   target_tracking_scaling_policy_configuration {
#     target_value = var.target_utilization_percent
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }

# # WRITE capacity target
# resource "aws_appautoscaling_target" "table_write" {
#   max_capacity       = var.wcu_max
#   min_capacity       = var.wcu_min
#   resource_id        = "table/${aws_dynamodb_table.this.name}"
#   scalable_dimension = "dynamodb:table:WriteCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "table_write_policy" {
#   name               = "${aws_dynamodb_table.this.name}-wcu-target"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.table_write.resource_id
#   scalable_dimension = aws_appautoscaling_target.table_write.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.table_write.service_namespace

#   target_tracking_scaling_policy_configuration {
#     target_value = var.target_utilization_percent
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }

# ############################################
# # Application Auto Scaling for GSI (example)
# ############################################

# # READ capacity for GSI1
# resource "aws_appautoscaling_target" "gsi1_read" {
#   max_capacity       = var.gsi_rcu_max
#   min_capacity       = var.gsi_rcu_min
#   resource_id        = "table/${aws_dynamodb_table.this.name}/index/gsi1"
#   scalable_dimension = "dynamodb:index:ReadCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "gsi1_read_policy" {
#   name               = "${aws_dynamodb_table.this.name}-gsi1-rcu-target"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.gsi1_read.resource_id
#   scalable_dimension = aws_appautoscaling_target.gsi1_read.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.gsi1_read.service_namespace

#   target_tracking_scaling_policy_configuration {
#     target_value = var.target_utilization_percent
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }

# # WRITE capacity for GSI1
# resource "aws_appautoscaling_target" "gsi1_write" {
#   max_capacity       = var.gsi_wcu_max
#   min_capacity       = var.gsi_wcu_min
#   resource_id        = "table/${aws_dynamodb_table.this.name}/index/gsi1"
#   scalable_dimension = "dynamodb:index:WriteCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "gsi1_write_policy" {
#   name               = "${aws_dynamodb_table.this.name}-gsi1-wcu-target"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.gsi1_write.resource_id
#   scalable_dimension = aws_appautoscaling_target.gsi1_write.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.gsi1_write.service_namespace

#   target_tracking_scaling_policy_configuration {
#     target_value = var.target_utilization_percent
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     scale_in_cooldown  = 60
#     scale_out_cooldown = 60
#   }
# }

# ########################################################################################
# # Helpful Outputs
# ########################################################################################
# output "table_name" {
#   value = aws_dynamodb_table.this.name
# }

# output "table_arn" {
#   value = aws_dynamodb_table.this.arn
# }

# output "table_stream_arn" {
#   value = aws_dynamodb_table.this.stream_arn
# }



# # ### Notes & production tips

# # * **Autoscaling vs On-Demand:** This configuration uses **PROVISIONED + Auto Scaling** (fine-grained control, predictable throttling). If you prefer **On-Demand**, set `billing_mode = "PAY_PER_REQUEST"` and **remove** all capacity and app-autoscaling resources.
# # * **Global Tables:** Add/adjust `var.replica_regions`. For **CMK per region**, supply `kms_key_arn` inside each `replica` block and create the keys in those regions.
# # * **Safety:** `deletion_protection_enabled = true` and `lifecycle.prevent_destroy = true` guard against accidental drops.
# # * **Streams:** Using `NEW_AND_OLD_IMAGES` gives maximum flexibility for consumers (e.g., Lambda).
# # * **TTL:** Store epoch seconds in the `ttl` attribute for item expiry.
# # * **SSE:** The example uses AWS-managed KMS. For stronger control/audit, switch to **customer-managed CMK** and supply `kms_key_arn`.

# # If you want, I can tailor this to your **naming/tagging standards**, add **CloudWatch alarms** for **throttling/consumed capacity**, or wire a **Lambda stream consumer** end-to-end.
