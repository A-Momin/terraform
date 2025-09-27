## ============================================================================
##         ORIGINAL: Not working as expected!!
## ============================================================================

# import sys
# from awsglue.transforms import *
# from awsglue.utils import getResolvedOptions
# from pyspark.context import SparkContext
# from awsglue.context import GlueContext
# from awsglue.job import Job

# S3_BUCKET_DATALAKE = "htech-datalake-bkt"
# CATALOG_DB_NAME = 'htech-catalog-db'
# TABLE_NAME = 'raw_customers'
# TARGET = f"{S3_BUCKET_DATALAKE}/processed/customers"

# # @params: [JOB_NAME]
# args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# sc = SparkContext()
# glueContext = GlueContext(sc)
# spark = glueContext.spark_session
# job = Job(glueContext)
# job.init(args['JOB_NAME'], args)

# datasource0 = glueContext.create_dynamic_frame.from_catalog(database = CATALOG_DB_NAME, table_name = TABLE_NAME, transformation_ctx = "datasource0")

# datasink4 = glueContext.write_dynamic_frame.from_options(frame = datasource0, connection_type = "s3", 
# connection_options = {"path": f"s3://{TARGET}/"}, format = "parquet", transformation_ctx = "datasink4")
# job.commit()

## ============================================================================
##                  REFACTORED
## ============================================================================

import sys
from pyspark.context import SparkContext
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job


S3_BUCKET_DATALAKE = "htech-datalake-bkt"
CATALOG_DB_NAME = 'htech-catalog-db'
TABLE_NAME = 'raw_customers'
TARGET = f"{S3_BUCKET_DATALAKE}/processed/customers"

sc = SparkContext()
glueContext = GlueContext(sc)

customersDF = glueContext.create_dynamic_frame.from_catalog(database=CATALOG_DB_NAME,table_name=TABLE_NAME)

glueContext.write_dynamic_frame.from_options(
    customersDF, 
    connection_type = "s3", 
    connection_options = {"path": f"s3://{TARGET}"}, 
    format = "parquet"
)