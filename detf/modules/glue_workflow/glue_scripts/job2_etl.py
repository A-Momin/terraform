import boto3
import io
import pandas as pd
import sys
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions
import pyspark.sql.functions as F

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

args = getResolvedOptions(sys.argv, ["WORKFLOW_NAME", "WORKFLOW_RUN_ID", "DATALAKE_BKT", "OUTPUT_KEY"])
# BKT_URL = f"s3://{args['DATALAKE_BKT']}"
curated_key = args['OUTPUT_KEY']

client = boto3.client("s3")
s3 = boto3.resource("s3")
glue_client = boto3.client("glue")


workflow_name = args["WORKFLOW_NAME"]
workflow_run_id = args["WORKFLOW_RUN_ID"]
workflow_params = glue_client.get_workflow_run_properties(Name=workflow_name, RunId=workflow_run_id)["RunProperties"]
processed_key = workflow_params["processed_key"]

obj = client.get_object(Bucket=args["DATALAKE_BKT"], Key=processed_key)

df = pd.read_csv(obj["Body"])

jsonBuffer = io.StringIO()

df.head(10).to_json(jsonBuffer, orient="records")
s3.Bucket(args["DATALAKE_BKT"]).put_object(Key=curated_key, Body=jsonBuffer.getvalue())