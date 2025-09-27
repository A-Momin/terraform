import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
import boto3
import json
from datetime import datetime

# Arguments passed from Terraform / Glue Job
args = getResolvedOptions(sys.argv, ["JOB_NAME", "CATALOG_DB_NAME", "TABLE_NAME", "data_quality_ruleset_id", "dq_results_path"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Initialize boto3 client for Glue Data Quality
glue_client = boto3.client('glue')

print(f"🚀 Starting Data Quality Evaluation for table: {args['TABLE_NAME']}")
print(f"📊 Using ruleset ID: {args['data_quality_ruleset_id']}")

# -------------------------------------------------------
# Load the customer data from Glue Catalog
# -------------------------------------------------------
try:
    customer_df = glueContext.create_dynamic_frame.from_catalog(
        database=args["CATALOG_DB_NAME"],
        table_name=args["TABLE_NAME"],
    )
    
    print(f"✅ Successfully loaded data from {args['CATALOG_DB_NAME']}.{args['TABLE_NAME']}")
    print(f"📈 Record count: {customer_df.count()}")
    
except Exception as e:
    print(f"❌ Error loading data from catalog: {str(e)}")
    raise e

# -------------------------------------------------------
# Run Data Quality Evaluation using GlueContext (no boto3)
# -------------------------------------------------------
try:
    dq_results = glueContext.start_data_quality_evaluation_run(
        customer_df,
        rulesetId=args["data_quality_ruleset_id"],
        publishingOptions={
            "resultsS3Prefix": args["dq_results_path"],
            "resultsPublishingEnabled": True,
            "cloudWatchMetricsEnabled": True,
        },
    )

    dq_results.printSchema()
    dq_results.show(truncate=False)

    dq_results.toDF().write.mode("overwrite").json(
        f"{args['dq_results_path']}/dq_results/"
    )

    print("✅ Data Quality evaluation completed and results written!")

except Exception as e:
    print(f"❌ Error during Data Quality evaluation: {str(e)}")
    raise


# # -------------------------------------------------------
# # Run Data Quality Evaluation using Glue API
# # -------------------------------------------------------
# try:
#     # Start Data Quality evaluation run
#     response = glue_client.start_data_quality_ruleset_evaluation_run(
#         DataSource={
#             "GlueTable": {
#                 "DatabaseName": args["CATALOG_DB_NAME"],
#                 "TableName": args["TABLE_NAME"],
#             }
#         },
#         Role=glueContext.get_conf("spark.glue.role"),  # Get the Glue job role
#         RulesetNames=[args["data_quality_ruleset_id"]],
#         ResultsS3Prefix=args["dq_results_path"],
#         PublishingOptions={
#             "EvaluationContext": "CustomerDQEvaluation",
#             "ResultsPublishingEnabled": True,
#             "CloudWatchMetricsEnabled": True,
#             "ResultsS3Prefix": args["dq_results_path"],
#         },
#     )
    
#     run_id = response['RunId']
#     print(f"🔄 Data Quality evaluation started with Run ID: {run_id}")
    
#     # Wait for the evaluation to complete
#     import time
#     max_wait_time = 600  # 10 minutes
#     wait_interval = 30   # 30 seconds
#     elapsed_time = 0
    
#     while elapsed_time < max_wait_time:
#         run_status = glue_client.get_data_quality_evaluation_run(RunId=run_id)
#         status = run_status['Status']
        
#         print(f"⏳ Evaluation status: {status}")
        
#         if status in ['SUCCEEDED', 'FAILED', 'STOPPED']:
#             break
            
#         time.sleep(wait_interval)
#         elapsed_time += wait_interval
    
#     if status == 'SUCCEEDED':
#         print("✅ Data Quality evaluation completed successfully!")
        
#         # Get the evaluation results
#         results = glue_client.get_data_quality_evaluation_run(RunId=run_id)
        
#         # Extract key metrics
#         evaluation_results = {
#             'run_id': run_id,
#             'status': status,
#             'start_time': str(results.get('StartedOn', '')),
#             'end_time': str(results.get('CompletedOn', '')),
#             'ruleset_id': args["data_quality_ruleset_id"],
#             'table_name': f"{args['CATALOG_DB_NAME']}.{args['TABLE_NAME']}",
#             'results_location': args["dq_results_path"],
#             'evaluation_timestamp': datetime.now().isoformat()
#         }
        
#         # Add detailed results if available
#         if 'ResultIds' in results:
#             evaluation_results['result_ids'] = results['ResultIds']
        
#         print(f"📊 Evaluation Results: {json.dumps(evaluation_results, indent=2)}")
        
#     else:
#         error_msg = f"❌ Data Quality evaluation failed with status: {status}"
#         print(error_msg)
#         if 'ErrorString' in run_status:
#             print(f"Error details: {run_status['ErrorString']}")
#         raise Exception(error_msg)

# except Exception as e:
#     print(f"❌ Error during Data Quality evaluation: {str(e)}")
#     raise e


# -------------------------------------------------------
# Alternative: Manual Data Quality Checks
# -------------------------------------------------------
print("\n🔍 Performing additional manual data quality checks...")

# Convert to Spark DataFrame for analysis
spark_df = customer_df.toDF()

# Basic data quality metrics
total_records = spark_df.count()
print(f"📊 Total records: {total_records}")

# Check for null values in key columns
key_columns = ['CUSTOMERID', 'CUSTOMERNAME', 'EMAIL']
null_checks = {}

for col in key_columns:
    if col in spark_df.columns:
        null_count = spark_df.filter(spark_df[col].isNull()).count()
        null_percentage = (null_count / total_records) * 100 if total_records > 0 else 0
        null_checks[col] = {
            'null_count': null_count,
            'null_percentage': round(null_percentage, 2)
        }
        print(f"🔍 {col}: {null_count} nulls ({null_percentage:.2f}%)")

# Check for duplicate CUSTOMERID
if 'CUSTOMERID' in spark_df.columns:
    unique_customers = spark_df.select('CUSTOMERID').distinct().count()
    duplicate_count = total_records - unique_customers
    print(f"🔍 Duplicate CUSTOMERID count: {duplicate_count}")

# Email format validation (basic check)
if 'EMAIL' in spark_df.columns:
    from pyspark.sql.functions import col
    
    valid_email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    invalid_emails = spark_df.filter(
        ~col('EMAIL').rlike(valid_email_pattern) & col('EMAIL').isNotNull()
    ).count()
    print(f"🔍 Invalid email formats: {invalid_emails}")

# -------------------------------------------------------
# Create comprehensive results summary
# -------------------------------------------------------
manual_dq_results = {
    'manual_checks': {
        'total_records': total_records,
        'null_checks': null_checks,
        'duplicate_customerid_count': duplicate_count if 'CUSTOMERID' in spark_df.columns else 0,
        'invalid_email_count': invalid_emails if 'EMAIL' in spark_df.columns else 0
    },
    'check_timestamp': datetime.now().isoformat(),
    'table_info': {
        'database': args["CATALOG_DB_NAME"],
        'table': args["TABLE_NAME"],
        'columns': spark_df.columns
    }
}

# -------------------------------------------------------
# Write comprehensive results to S3
# -------------------------------------------------------
try:
    # Create results DataFrame
    results_data = [manual_dq_results]
    results_df = spark.createDataFrame([results_data])
    
    # Write to S3 as JSON
    output_path = f"{args['dq_results_path']}/manual_checks/"
    results_df.write.mode("overwrite").json(output_path)
    
    print(f"✅ Manual data quality results written to: {output_path}")
    
    # Also write as a single JSON file for easy reading
    import boto3
    s3_client = boto3.client('s3')
    
    # Extract bucket and key from S3 path
    s3_path = args["dq_results_path"].replace("s3://", "")
    bucket_name = s3_path.split("/")[0]
    key_prefix = "/".join(s3_path.split("/")[1:])
    
    summary_key = f"{key_prefix}/dq_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    
    s3_client.put_object(
        Bucket=bucket_name,
        Key=summary_key,
        Body=json.dumps(manual_dq_results, indent=2),
        ContentType='application/json'
    )
    
    print(f"✅ Summary report written to: s3://{bucket_name}/{summary_key}")

except Exception as e:
    print(f"⚠️ Warning: Could not write results to S3: {str(e)}")

print("\n🎉 Data Quality Evaluation job completed successfully!")
print(f"📍 Results location: {args['dq_results_path']}")

job.commit()