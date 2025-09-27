
## ============================================================================
##                  NOT TESTED YET!
## ============================================================================

import sys, logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job


# Initialize logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)



# Get parameters passed to the Glue job
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'catalog_db_name', 'table_name', 'target'])

CATALOG_DB_NAME = args['catalog_db_name']
TABLE_NAME = args['table_name']
TARGET = args['target']

logger.info(f"Starting ETL job Processing with source: {CATALOG_DB_NAME} and target: {TARGET}")

sc = SparkContext()
glueContext = GlueContext(sc)

customersDF = glueContext.create_dynamic_frame.from_catalog(database=CATALOG_DB_NAME,table_name=TABLE_NAME)

glueContext.write_dynamic_frame.from_options(
    customersDF, 
    connection_type = "s3", 
    connection_options = {"path": TARGET}, 
    format = "parquet"
)