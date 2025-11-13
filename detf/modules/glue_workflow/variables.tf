# variable "glue_catalog_databases" {
#   type = any
# }


variable "datalake_bkt" {
  type = any
}

variable "glue_assets_bkt" {
  type = any
}

# variable "glue_temp_bkt" {
#   type = any
# }

variable "prefix" {
  type    = string
  default = "GWF"
}

variable "lfn_layer_arn" {
  type = string
}
