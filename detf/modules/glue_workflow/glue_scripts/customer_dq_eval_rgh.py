import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
import boto3
import json
from datetime import datetime

# from awsglue.data_quality import DataQuality  # Import the DataQuality class
from awsglue.dataquality import DataQuality, DataQualityRule, DataQualityRuleSet


#################################################################################

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dataquality import DataQuality, DataQualityRule, DataQualityRuleSet
from awsglue.dynamicframe import DynamicFrame

#################################################################################

# Print boto3 version for diagnostic purposes
print(f"Boto3 version in Glue job: {boto3.__version__}")

# Arguments passed from Terraform / Glue Job
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "CATALOG_DB_NAME",
        "TABLE_NAME",
        "data_quality_ruleset_id",
        "dq_results_path",
    ],
)

# sc = SparkContext()
# glueContext = GlueContext(sc)
# spark = glueContext.spark_session
# job = Job(glueContext)
# job.init(args["JOB_NAME"], args)

# print(f"🚀 Starting Data Quality Evaluation for table: {args['TABLE_NAME']}")
# print(f"📊 Using ruleset ID: {args['data_quality_ruleset_id']}")

# # -------------------------------------------------------
# # Load the customer data from Glue Catalog
# # -------------------------------------------------------
# try:
#     customer_df = glueContext.create_dynamic_frame.from_catalog(
#         database=args["CATALOG_DB_NAME"],
#         table_name=args["TABLE_NAME"],
#     )

#     print(
#         f"✅ Successfully loaded data from {args['CATALOG_DB_NAME']}.{args['TABLE_NAME']}"
#     )
#     print(f"📈 Record count: {customer_df.count()}")

# except Exception as e:
#     print(f"❌ Error loading data from catalog: {str(e)}")
#     raise e

###############################################################################

# Initialize Glue Context
glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Define Data Quality rules
rules = [
    DataQualityRule(column="Email", expression="Email LIKE '%@%.%'", name="Valid Email Format"),
    DataQualityRule(column="CUSTOMERID", expression="CUSTOMERID IS UNIQUE", name="Unique IDs"),
]

rule_set = DataQualityRuleSet(name="DummyRuleSet", rules=rules)

# Load Data
datasource0 = glueContext.create_dynamic_frame.from_catalog(
    database=args["CATALOG_DB_NAME"],
    table_name=args["TABLE_NAME"],
)

# Apply Data Quality rules
dq_results = DataQuality().evaluate(glueContext, datasource0, rule_sets=[rule_set])

print(dq_results)


# Extract results
results = dq_results["Result"]

# Display results
for result in results:
    print(f"Rule: {result['RuleName']}")
    print(f"Column: {result['Column']}")
    print(f"Passed: {result['PassedCount']}")
    print(f"Failed: {result['FailedCount']}")
    print(f"Total: {result['TotalCount']}")
    print(f"Pass Percentage: {result['PassPercentage']}%")
    print(f"Fail Percentage: {result['FailPercentage']}%")
    print("=" * 40)

# Continue with your ETL process


# # -------------------------------------------------------
# # Run Data Quality Evaluation using awsglue.data_quality module
# # -------------------------------------------------------
# try:
#     # Instantiate the DataQuality class with the GlueContext
#     data_quality = DataQuality(glueContext)

#     # Use the evaluate_data_quality_ruleset() method with the DynamicFrame
#     # This method directly handles the evaluation and publishing of results
#     dq_eval_results_df = data_quality.evaluate_data_quality_ruleset(
#         data_frame=customer_df,
#         ruleset_id=args["data_quality_ruleset_id"],
#         publishing_options={
#             "dataQualityEvaluationContext": "CustomerDQEvaluation",
#             "resultsPublishingEnabled": True,
#             "cloudWatchMetricsEnabled": True,
#             "resultsS3Prefix": args["dq_results_path"],
#         },
#     )

#     print(f"✅ Data Quality evaluation initiated and results collected.")
#     print(
#         f"📊 DQ Evaluation Results DynamicFrame schema: {dq_eval_results_df.printSchema()}"
#     )

#     # -------------------------------------------------------
#     # Write results to S3 in JSON
#     # The dq_eval_results_df is already a DynamicFrame representing the evaluation output
#     # -------------------------------------------------------
#     output_path = f"{args['dq_results_path']}glue_managed_results/"
#     dq_eval_results_df.toDF().write.mode("overwrite").json(output_path)

#     print(f"✅ Glue-managed Data Quality Evaluation results written to {output_path}")

# except Exception as e:
#     print(
#         f"❌ Error during Data Quality evaluation using awsglue.data_quality: {str(e)}"
#     )
#     # If the ModuleNotFoundError for awsglue.data_quality persists, it will be caught here.
#     # Check the logs for the exact error, as it might reveal deeper environment issues.
#     raise e

# -------------------------------------------------------
# Manual Data Quality Checks (optional, as you had them)
# This part remains mostly the same for additional custom checks
# -------------------------------------------------------

# print("\n🔍 Performing additional manual data quality checks...")

# spark_df = customer_df.toDF()
# total_records = spark_df.count()
# print(f"📊 Total records: {total_records}")

# key_columns = ["CUSTOMERID", "CUSTOMERNAME", "EMAIL"]
# null_checks = {}
# duplicate_count = 0
# invalid_emails = 0

# for col_name in key_columns:
#     if col_name in spark_df.columns:
#         null_count = spark_df.filter(spark_df[col_name].isNull()).count()
#         null_percentage = (null_count / total_records) * 100 if total_records > 0 else 0
#         null_checks[col_name] = {
#             "null_count": null_count,
#             "null_percentage": round(null_percentage, 2),
#         }
#         print(f"🔍 {col_name}: {null_count} nulls ({null_percentage:.2f}%)")

# if "CUSTOMERID" in spark_df.columns:
#     unique_customers = spark_df.select("CUSTOMERID").distinct().count()
#     duplicate_count = total_records - unique_customers
#     print(f"🔍 Duplicate CUSTOMERID count: {duplicate_count}")

# if "EMAIL" in spark_df.columns:
#     from pyspark.sql.functions import col, regexp_extract

#     valid_email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
#     invalid_emails = spark_df.filter(
#         ~col("EMAIL").rlike(valid_email_pattern) & col("EMAIL").isNotNull()
#     ).count()
#     print(f"🔍 Invalid email formats: {invalid_emails}")

# manual_dq_results = {
#     "manual_checks": {
#         "total_records": total_records,
#         "null_checks": null_checks,
#         "duplicate_customerid_count": duplicate_count,
#         "invalid_email_count": invalid_emails,
#     },
#     "check_timestamp": datetime.now().isoformat(),
#     "table_info": {
#         "database": args["CATALOG_DB_NAME"],
#         "table": args["TABLE_NAME"],
#         "columns": spark_df.columns,
#     },
# }

# try:
#     s3_client = boto3.client("s3")
#     s3_path_parts = args["dq_results_path"].replace("s3://", "").split("/", 1)
#     bucket_name = s3_path_parts[0]
#     key_prefix = s3_path_parts[1] if len(s3_path_parts) > 1 else ""

#     summary_key = f"{key_prefix}/manual_dq_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

#     s3_client.put_object(
#         Bucket=bucket_name,
#         Key=summary_key,
#         Body=json.dumps(manual_dq_results, indent=2),
#         ContentType="application/json",
#     )

#     print(f"✅ Manual DQ summary report written to: s3://{bucket_name}/{summary_key}")

# except Exception as e:
#     print(f"⚠️ Warning: Could not write manual DQ summary to S3: {str(e)}")

# print("\n🎉 Data Quality Evaluation job completed successfully!")
# print(f"📍 Results location: {args['dq_results_path']}")

job.commit()
