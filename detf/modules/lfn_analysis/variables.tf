variable "cw_events" {
  description = "AWS CloudWatch Rules"
  type        = map(string)
  default = {
    come_to_work = "cron(0 17 ? * MON-FRI *)" ## "rate(5 minutes)" ## 
    daily_tasks  = "cron(0 17 ? * MON-FRI *)"
    pickup       = "cron(0 22 ? * MON-FRI *)"
  }
}

variable "cuckoo_s3_objects" {
  type        = list(string)
  description = "Folders in a s3 Bucket"
  default     = ["email-templates", "AWS-EFS-Data"]
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = map(string)
}
