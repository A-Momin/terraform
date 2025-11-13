module "ec2_dev_environment" {
  source    = "./modules/ec2_dev_environment"
  vpc_id    = aws_vpc.detf_vpc.id
  subnet_id = element([for k, v in aws_subnet.public_subnets : v.id if strcontains(k, "public")], 0)
}

module "ecs_analysis" {
  source = "./modules/ecs_analysis"

  django_secret_key             = var.django_secret_key
  django_stripe_secret_key      = var.django_stripe_secret_key
  django_stripe_endpoint_secret = var.django_stripe_endpoint_secret

  r53_hosted_zone = aws_route53_zone.harnesstech_public_zone
  vpc             = aws_vpc.detf_vpc
  public_subnets  = aws_subnet.public_subnets
  private_subnets = aws_subnet.private_subnets
}

# module "lfn_analysis" {
#   source  = "./modules/lfn_analysis"
#   vpc_id  = aws_vpc.detf_vpc.id
#   subnets = { for k, v in aws_subnet.public_subnets : k => v.id }
# }

# module "glue_event_based_pipeline" {
#   source                 = "./modules/glue_event_based_pipeline"
#   vpc_id                 = aws_vpc.detf_vpc.id
#   subnets                = { for k, v in aws_subnet.public_subnets : k => v.id }
#   glue_catalog_databases = aws_glue_catalog_database.glue_catalog_databases
#   datalake_bkt           = aws_s3_bucket.s3_buckets[var.BUCKETS[0]]
#   glue_assets_bkt        = aws_s3_bucket.s3_buckets[var.BUCKETS[1]]
#   glue_temp_bkt          = aws_s3_bucket.s3_buckets[var.BUCKETS[2]]
#   lftn_admin_user        = aws_iam_user.lftn_user
# }

# module "redshift_analysis" {
#   source                   = "./modules/redshift_analysis"
#   vpc_id                   = aws_vpc.detf_vpc.id
#   vpc_cidr                 = var.VPC_CIDR
#   public_subnets           = aws_subnet.public_subnets
#   redshift_master_username = var.redshift_master_username
#   redshift_master_password = var.redshift_master_password
# }

# module "route53_lb_asg" {
#   source          = "./modules/route53_lb_asg"
#   r53_hosted_zone = aws_route53_zone.harnesstech_public_zone
#   vpc             = aws_vpc.detf_vpc
#   public_subnets  = aws_subnet.public_subnets
#   private_subnets = aws_subnet.private_subnets
# }


# module "glue_workflow" {
#   source          = "./modules/glue_workflow"
#   datalake_bkt    = aws_s3_bucket.s3_buckets[var.BUCKETS[0]]
#   glue_assets_bkt = aws_s3_bucket.s3_buckets[var.BUCKETS[1]]
#   lfn_layer_arn   = aws_lambda_layer_version.lfn_layer.arn
# }

