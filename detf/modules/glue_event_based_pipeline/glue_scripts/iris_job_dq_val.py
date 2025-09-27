import os, sys
# os.environ['SPARK_VERSION'] = '3.1'

import pydeequ
from pydeequ.checks import *
from pydeequ.verification import *

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
import boto3

from awsglue.utils import getResolvedOptions

args = getResolvedOptions(sys.argv, ["JOB_NAME", "SOURCE_DATA", "DQ_VALIDATION_OUTPUT"])


SOURCE_DATA = args["SOURCE_DATA"]
DQ_VALIDATION_OUTPUT = args["DQ_VALIDATION_OUTPUT"]

spark = (SparkSession
             .builder
             .config("spark.jars.packages", pydeequ.deequ_maven_coord)
             .config("spark.jars.excludes", pydeequ.f2j_maven_coord)
             .appName('Test Data Quality')
             .getOrCreate())

# SOURCE_DATA ='s3://dqcheckyt/input_file/set2_proper.csv'

dataset = spark.read.option('header', 'true').option("delimiter", ",").csv(SOURCE_DATA)

print("Schema of input file:")
dataset.printSchema()

check = Check(spark, CheckLevel.Warning, "Glue PyTest")


checkResult = VerificationSuite(spark) \
        .onData(dataset) \
        .addCheck(check.isUnique('Id') \
            .isComplete("CLASS_NAME")  \
            .isNonNegative("PETAL_LENGTH")  \
            .isContainedIn("CLASS_NAME",["Iris-virginica","Iris-setosa"])) \
        .run()


print("Showing VerificationResults:")
checkResult_df = VerificationResult.checkResultsAsDataFrame(spark, checkResult)
checkResult_df.show(truncate=False)

# DQ_VALIDATION_OUTPUT ="s3://dqcheckyt/validation_output/"
checkResult_df.repartition(1).write.option("header", "true").mode('append').csv(DQ_VALIDATION_OUTPUT, sep=',')


# Filtering for any failed data quality constraints
df_checked_constraints_failures = (checkResult_df[checkResult_df['constraint_status'] == "Failure"])


if df_checked_constraints_failures.count() > 0:
  deequ_check_pass = "Fail"
else:
  deequ_check_pass = "Pass"
    
# Print the value of deequ_check_pass environment variable 
print("deequ_check_pass = ", deequ_check_pass)
