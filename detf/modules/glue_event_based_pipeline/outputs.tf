output "LFN_ROLE_NAME" {
  value = aws_iam_role.lfn_role.name
}

output "LFN_ROLE_ARN" {
  value = aws_iam_role.lfn_role.arn
}

output "GLUE_ROLE_NAME" {
  value = aws_iam_role.glue_role.name
}


output "GLUE_ROLE_ARN" {
  value = aws_iam_role.glue_role.arn
}

output "TOPIC_NAME" {
  value = aws_sns_topic.glue_sns_topic.name
}


output "CUSTOMER_CRAWLER_LFN_NAME" {
  value = aws_lambda_function.s3_customer_crawler_triggerer.function_name
}

output "CUSTOMER_JOB_STARTER_LFN_NAME" {
  value = aws_lambda_function.glue_job_starter.function_name
}

output "S3_CUSTOMER_CRAWLER_NAME" {
  value = aws_glue_crawler.s3_customer_crawler.name
}

output "CUSTOMER_PROCESSING_JOB_NAME" {
  value = aws_glue_job.customer_processing_job.name
}


# output "CUSTOMER_DQ_EVAL_JOB_NAME" {
#   value = ""
# }

# output "CUSTOMER_DQ_RULESET_NAME" {
#   value = aws_glue_data_quality_ruleset.customer_dq_eval_ruleset.name
# }

# output "CUSTOMER_DQ_EVAL_RESULTS_S3_PATH" {
#   value = "s3://${var.datalake_bkt.bucket}/DQ-Evaluations/customers_dqe/"
# }



# output "CUSTOMER_DQ_REQ_RUN_ID" {
#   value = aws_glue_data_quality_ruleset.customer_dq_eval_ruleset.recommendation_run_id
# }


output "S3_CUSTOMER_CRAWLER_RULE_NAME" {
  value = ""
}

output "S3_CUSTOMER_PROCESSING_JOB_RULE_NAME" {
  value = ""
}

output "lftn_admin_user" {
  value = ""
}

output "SNS_EMAIL_ENDPOINT" {
  value = ""
}

output "vpc_id" {
  value = ""
}

output "subnets" {
  value = ""
}

output "datalake_bkt" {
  value = ""
}

output "glue_assets_bkt" {
  value = ""
}

output "glue_temp_bkt" {
  value = ""
}


output "s3_customer_crawler_name" {
  description = "The name of the Glue Crawler for the S3 Customer data."
  value       = aws_glue_crawler.s3_customer_crawler.name

}

output "s3_customer_processing_job_name" {
  description = "The name of the Glue Crawler for the S3 Customer data."
  value       = aws_glue_job.customer_processing_job.name

}

