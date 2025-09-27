import sys
import logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

from mylogger import CustomLogger




args = getResolvedOptions(sys.argv, ["JOB_NAME", "S3_BUCKET_DATALAKE", "CATALOG_DB_NAME", "TABLE_NAME", "TARGET"])



JOB_NAME = args.get("JOB_NAME")
S3_BUCKET_DATALAKE = args.get("S3_BUCKET_DATALAKE")
CATALOG_DB_NAME = args.get("CATALOG_DB_NAME")
TABLE_NAME = args.get("TABLE_NAME")
TARGET = args.get("TARGET")

print(f"Job Name: {JOB_NAME}")
print(f"S3 Bucket Datalake: {S3_BUCKET_DATALAKE}")
print(f"Catalog DB Name: {CATALOG_DB_NAME}")
print(f"Table Name: {TABLE_NAME}")
print(f"Target Path: {TARGET}")


# S3_BUCKET_DATALAKE = "htech-datalake-bkt"
# CATALOG_DB_NAME = 'htech-catalog-db'
# TABLE_NAME = 'raw_customers'
# TARGET = f"s3://{S3_BUCKET_DATALAKE}/processed/customers/"


sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# avoiding complex logging setup before SparkContext() is initialized
logger = CustomLogger()


job = Job(glueContext)
job.init(args['JOB_NAME'], args)

datasource0 = glueContext.create_dynamic_frame.from_catalog(database = CATALOG_DB_NAME, table_name = TABLE_NAME, transformation_ctx = "datasource0")

datasink4 = glueContext.write_dynamic_frame.from_options(frame = datasource0, connection_type = "s3",
connection_options = {"path": TARGET}, format = "parquet", transformation_ctx = "datasink4")

job.commit()
