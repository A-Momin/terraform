locals {
  gcdb_bronze = split("-", var.glue_catalog_databases["gcdb-bronze"].name)
  gcdb_silver = split("-", var.glue_catalog_databases["gcdb-silver"].name)
  #   gcdb_gold   = split("-", var.glue_catalog_databases["gcdb_gold"].name)
}

locals {
  bronze = local.gcdb_bronze[length(local.gcdb_bronze) - 1]
  silver = local.gcdb_silver[length(local.gcdb_silver) - 1]
  #   gold   = local.gcdb_gold[length(local.gcdb_gold) - 1]
}
