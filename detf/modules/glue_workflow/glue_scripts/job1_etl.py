import sys, boto3, io
import pandas as pd
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions
import pyspark.sql.functions as F

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Input/Output via job args (Glue passes them via default_arguments if set)
# args = sys.argv
args = getResolvedOptions(sys.argv, ["WORKFLOW_NAME", "WORKFLOW_RUN_ID", "DATALAKE_BKT", "INPUT_KEY", "OUTPUT_KEY"])


# BKT_URL = f's3://{args["DATALAKE_BKT"]}'

processed_key = args['OUTPUT_KEY']

client = boto3.client("s3")
s3 = boto3.resource("s3")
glue_client = boto3.client("glue")

obj = client.get_object(Bucket=args["DATALAKE_BKT"], Key=args['INPUT_KEY'])

df = pd.read_csv(obj["Body"])

jsonBuffer = io.StringIO()

df.head(10).to_json(jsonBuffer, orient="records")
s3.Bucket(args["DATALAKE_BKT"]).put_object(Key=processed_key, Body=jsonBuffer.getvalue())

###############################################################################
workflow_name = args["WORKFLOW_NAME"]
workflow_run_id = args["WORKFLOW_RUN_ID"]
workflow_params = glue_client.get_workflow_run_properties(Name=workflow_name, RunId=workflow_run_id)["RunProperties"]

workflow_params["processed_key"] = processed_key # add/update param
glue_client.put_workflow_run_properties(Name=workflow_name, RunId=workflow_run_id, RunProperties=workflow_params)