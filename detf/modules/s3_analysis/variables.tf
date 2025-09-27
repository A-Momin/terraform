########################################
# variables.tf (inline for brevity)
########################################
variable "project" {
  type    = string
  default = "demo-s3"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "primary_bkt_region" {
  type    = string
  default = "us-east-1"
}
# replica region example for cross-region replication
variable "replica_region" {
  type    = string
  default = "us-west-2"
}
variable "enable_transfer_acceleration" {
  type    = bool
  default = false
}
variable "enable_website_hosting" {
  type    = bool
  default = false
}
variable "primary_bkt_name" {
  type    = string
  default = "${var.project}-${var.environment}-bucket"
}
