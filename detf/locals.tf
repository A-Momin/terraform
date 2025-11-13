# locals {
#   datalake_stages        = ["bronze", "silver", "gold", "DQE-Results", "raw", "processed", "curated"]
#   datalake_prefixes      = ["customers", "sales", "automobile"]
#   misc_datalake_prefixes = ["athena-outputs/", "DQE-Results/customers_failed/"]
# }

locals {
  #   datalake_bucket_prefixes = concat(flatten([for stage in local.datalake_stages : [for prefix in local.datalake_prefixes : "${stage}/${prefix}/"]]), local.misc_datalake_prefixes)
  datalake_bucket_prefixes = [
    "bronze/customers/",
    "bronze/sales/",
    "bronze/automobile/",
    "silver/customers/",
    "silver/sales/",
    "silver/automobile/",
    "gold/customers/",
    "gold/sales/",
    "gold/automobile/",
    "DQE-Results/customers_failed/",
    "raw/",
    "processed/",
    "curated/",
    "athena-outputs/"
  ]
  glue_assets_bkt_prefixes = [
    "glue_scripts/",
    "lfn_deployment_pkg/",
    "temporary/",
    "sparkHistoryLogs/",
    "libraries/",
    "misc/"
  ]
}
