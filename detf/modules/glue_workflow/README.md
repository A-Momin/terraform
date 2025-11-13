###############################################################################
################################ NOT COMPLETLY TESTED ###################################
###############################################################################

**ChatGPT**: I like to learn in details how aws Glue Workflow and Triggers works. for this learning purpose create real-world and practical demonstration. For this demonstration, write a terraform script to provision cloud infrastruction on AWS with all other python glue-job script and lambda function with python Runtime.

---

-   A Terraform project (IAM, S3, Glue Catalog, two Glue jobs, a Glue workflow, and Glue triggers).
-   Two example Glue PySpark job scripts (`job1` & `job2`) that read/write S3.
-   A Python Lambda that starts the Glue workflow (invoked by S3 `PUT` via EventBridge).
-   A small `Makefile` / packaging helper and README showing how to deploy.

I’ll explain how the workflow and triggers connect and include links to the Terraform docs I used for reference. ([registry.terraform.io][1])

---

## High level architecture (what you’ll provision)

1. `s3://<bucket>/raw/` — incoming files. S3 PUT event -> EventBridge -> Lambda.
2. Lambda -> `glue.start_workflow_run(Name='demo-glue-workflow')`.
3. Glue Workflow `demo-glue-workflow`:

    - Job A (`glue-job-01`) — reads from `raw/`, writes to `staging/`.
    - Job B (`glue-job-02`) — runs **after** Job A succeeds, reads `staging/`, writes to `processed/`.

4. Glue triggers:

    - `trigger-start-jobA` — ON_DEMAND action that runs `glue-job-01` when workflow run starts.
    - `trigger-after-jobA` — CONDITIONAL trigger that starts `glue-job-02` when `glue-job-01` succeeds.

5. Glue Catalog database for tables (optional, shown but not strictly required).

This pattern mirrors common ETL pipelines: upload raw file → start workflow → chained jobs with success/failure gating. Docs: Glue Workflows & Triggers. ([AWS Documentation][2])

---

## Files I’ll provide in this message

-   `terraform/`

    -   `main.tf` — provider + resources
    -   `variables.tf`
    -   `outputs.tf`
    -   `lambda_policy.json` — simple IAM policy for Lambda
    -   `glue_assume_role_policy.json` — role trust policy for Glue

-   `glue/scripts/`

    -   `job1_etl.py` — Glue PySpark job 1 (read raw -> cleanse -> write staging)
    -   `job2_etl.py` — Glue PySpark job 2 (read staging -> aggregate -> write processed)

-   `lambda/`

    -   `start_workflow_lambda.py` — Python lambda which calls `glue.start_workflow_run`
    -   `requirements.txt` (optional, if packaging)

-   `Makefile` — helpers to package the lambda and run `terraform init && terraform apply -auto-approve` (local steps)
-   `README.md` — quick deploy instructions and notes.

Below are the files. Copy them into a project directory and follow the README steps at the end.

---

# 1) Terraform — `terraform/main.tf`

> Note: This Terraform is intentionally simple for learning/demo — in production you should harden IAM, enable encryption at rest, use KMS, enable logging, implement least-privilege policies, remote state, and CI/CD. The glue trigger/job syntax follows the official Terraform AWS provider resources. ([registry.terraform.io][1])

```ini
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

#######################
# S3 buckets
#######################
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = false
  }
}

# Upload Glue scripts to S3 (assumes files exist locally)
resource "aws_s3_bucket_object" "glue_job1_script" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "scripts/job1_etl.py"
  source = "${path.module}/../glue/scripts/job1_etl.py"
  etag   = filemd5("${path.module}/../glue/scripts/job1_etl.py")
}

resource "aws_s3_bucket_object" "glue_job2_script" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "scripts/job2_etl.py"
  source = "${path.module}/../glue/scripts/job2_etl.py"
  etag   = filemd5("${path.module}/../glue/scripts/job2_etl.py")
}

# Upload Lambda code zip (assumes you build lambda.zip into ../lambda/lambda.zip)
resource "aws_s3_bucket_object" "lambda_zip" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "lambda/start_workflow_lambda.zip"
  source = "${path.module}/../lambda/lambda.zip"
  etag   = filemd5("${path.module}/../lambda/lambda.zip")
}

#######################
# IAM: Glue Role and Policy
#######################
resource "aws_iam_role" "glue_service_role" {
  name               = "${var.prefix}-glue-role"
  assume_role_policy = file("${path.module}/glue_assume_role_policy.json")
}

# Attach managed policy for Glue (glue service role)
resource "aws_iam_role_policy_attachment" "glue_service_managed" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Inline policy to allow S3 read/write to our bucket and start/stop workflows
resource "aws_iam_policy" "glue_extra_policy" {
  name = "${var.prefix}-glue-extra-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:GetWorkflowRun",
          "glue:GetWorkflowRuns",
          "glue:StartWorkflowRun"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_extra_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_extra_policy.arn
}

#######################
# IAM: Lambda Role
#######################
resource "aws_iam_role" "lambda_role" {
  name               = "${var.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.prefix}-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "glue:StartWorkflowRun"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

#######################
# Glue Catalog Database
#######################
resource "aws_glue_catalog_database" "demo_db" {
  name = "${var.prefix}_db"
}

#######################
# Glue Jobs
#######################
resource "aws_glue_job" "job1" {
  name     = "${var.prefix}-glue-job-01"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.data_bucket.bucket}/scripts/job1_etl.py"
  }

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${aws_s3_bucket.data_bucket.bucket}/temp/"
    "--extra-py-files" = "" # add if you package deps
  }
  max_retries = 0
  glue_version = "3.0"
  number_of_workers = 2
  worker_type = "G.1X"
}

resource "aws_glue_job" "job2" {
  name     = "${var.prefix}-glue-job-02"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.data_bucket.bucket}/scripts/job2_etl.py"
  }

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${aws_s3_bucket.data_bucket.bucket}/temp/"
  }
  max_retries = 0
  glue_version = "3.0"
  number_of_workers = 2
  worker_type = "G.1X"
}

#######################
# Glue Workflow
#######################
resource "aws_glue_workflow" "example" {
  name = "${var.prefix}-glue-workflow"
  description = "Demo workflow with two jobs chained via triggers"
}

#######################
# Glue Triggers: job1 runs when workflow starts; job2 runs when job1 succeeds
#######################
# Trigger: ON_DEMAND (will be invoked by workflow start)
resource "aws_glue_trigger" "trigger_job1" {
  name = "${var.prefix}-trigger-job1"
  type = "ON_DEMAND"

  actions {
    job_name = aws_glue_job.job1.name
  }

  workflow_name = aws_glue_workflow.example.name
}

# Trigger: CONDITIONAL, starts job2 when job1 SUCCESS
resource "aws_glue_trigger" "trigger_after_job1" {
  name = "${var.prefix}-trigger-after-job1"
  type = "CONDITIONAL"

  actions {
    job_name = aws_glue_job.job2.name
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name         = aws_glue_job.job1.name
      state            = "SUCCEEDED"
    }
  }

  workflow_name = aws_glue_workflow.example.name
}

#######################
# Lambda: start workflow on S3 put (EventBridge rule)
#######################
resource "aws_lambda_function" "start_workflow" {
  function_name = "${var.prefix}-start-glue-workflow"
  s3_bucket     = aws_s3_bucket.data_bucket.bucket
  s3_key        = aws_s3_bucket_object.lambda_zip.key
  handler       = "start_workflow_lambda.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
}

# EventBridge rule to capture s3:Object Created and trigger Lambda (pattern uses s3 Put events via aws:s3)
resource "aws_cloudwatch_event_rule" "s3_put_rule" {
  name = "${var.prefix}-s3-put-rule"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": [aws_s3_bucket.data_bucket.id]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "rule_target_lambda" {
  rule = aws_cloudwatch_event_rule.s3_put_rule.name
  target_id = "invoke-lambda"
  arn = aws_lambda_function.start_workflow.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_workflow.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_put_rule.arn
}

#######################
# Outputs
#######################
output "s3_bucket" {
  value = aws_s3_bucket.data_bucket.bucket
}

output "glue_workflow" {
  value = aws_glue_workflow.example.name
}

output "glue_job_names" {
  value = [aws_glue_job.job1.name, aws_glue_job.job2.name]
}
```

---

# 2) Terraform variables — `terraform/variables.tf`

```ini
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "prefix" {
  type    = string
  default = "demo"
}

variable "bucket_name" {
  type    = string
  description = "S3 bucket name - must be globally unique"
}
```

---

# 3) Glue assume role policy — `terraform/glue_assume_role_policy.json`

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "glue.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

---

# 4) Lambda code — `lambda/start_workflow_lambda.py`

This Lambda reads the EventBridge event (S3 object created), logs some fields and starts the Glue workflow using boto3. This is the canonical approach (start_workflow_run). Example reference shows exactly this usage. ([Stack Overflow][3])

```python
import json
import os
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

GLUE_WORKFLOW_NAME = os.environ.get("GLUE_WORKFLOW", "demo-glue-workflow")  # set via TF or console

glue = boto3.client("glue")

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    # Extract bucket/key from the EventBridge S3 detail if present
    try:
        detail = event.get("detail", {})
        bucket = detail.get("bucket", {}).get("name")
        key = detail.get("object", {}).get("key")
        logger.info("S3 event for bucket=%s key=%s", bucket, key)
    except Exception:
        logger.exception("Could not parse event detail")

    # Start the Glue workflow
    try:
        resp = glue.start_workflow_run(Name=GLUE_WORKFLOW_NAME)
        logger.info("Started workflow %s run id=%s", GLUE_WORKFLOW_NAME, resp.get("RunId"))
        return {"statusCode": 200, "body": json.dumps({"runId": resp.get("RunId")})}
    except Exception as e:
        logger.exception("Failed to start Glue workflow")
        raise
```

**Important**: When you deploy the Lambda, set an environment variable `GLUE_WORKFLOW` equal to the Terraform-created workflow name, or edit the code to expect the name you output from Terraform.

---

# 5) Glue job scripts

These are small PySpark-style Glue scripts. They use GlueContext and DynamicFrame.

## `glue/scripts/job1_etl.py` (job 1 — read raw, clean, write staging)

```python
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
import sys
import boto3
import pyspark.sql.functions as F

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Input/Output via job args (Glue passes them via default_arguments if set)
args = sys.argv

# Simple hard-coded paths (you can pass them through --JOB_ARGUMENTS)
INPUT_PREFIX = "s3://{bucket}/raw/".format(bucket="<<REPLACE_BUCKET>>")
OUTPUT_PREFIX = "s3://{bucket}/staging/".format(bucket="<<REPLACE_BUCKET>>")

# Example: read CSVs (or parquet if you prefer)
df = spark.read.option("header", "true").csv(INPUT_PREFIX)

# Simple transformation: drop rows where id is null and trim whitespace
df2 = df.filter(F.col("id").isNotNull())
for c in df2.columns:
    df2 = df2.withColumn(c, F.trim(F.col(c)))

# Write out as parquet for job2
df2.write.mode("overwrite").parquet(OUTPUT_PREFIX)
print("Wrote staging data to", OUTPUT_PREFIX)
```

> Replace `<<REPLACE_BUCKET>>` with the bucket name (or pass paths via Glue job arguments `--extra-py-files` or `--JOB-ARGS`). For demo, you can hard-code or parameterize.

## `glue/scripts/job2_etl.py` (job 2 — read staging, aggregate, write processed)

```python
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
import pyspark.sql.functions as F

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

STAGING_PREFIX = "s3://{bucket}/staging/".format(bucket="<<REPLACE_BUCKET>>")
PROCESSED_PREFIX = "s3://{bucket}/processed/".format(bucket="<<REPLACE_BUCKET>>")

df = spark.read.parquet(STAGING_PREFIX)

# Example aggregation: count by category
if "category" in df.columns:
    agg = df.groupBy("category").agg(F.count("*").alias("cnt"))
else:
    agg = df.agg(F.count("*").alias("cnt"))

agg.write.mode("overwrite").parquet(PROCESSED_PREFIX)
print("Wrote processed data to", PROCESSED_PREFIX)
```

---

# 6) Packaging the Lambda

Terraform expects `lambda.zip` in `../lambda/lambda.zip` (relative to `terraform/`). Create a zip containing `start_workflow_lambda.py`:

```bash
cd lambda
zip lambda.zip start_workflow_lambda.py
# (optional) include any dependencies - for simple boto3, Lambda runtime has boto3 built-in.
```

You can use the included `Makefile` snippet below.

---

# 7) Simple Makefile (project root)

```makefile
.PHONY: package-lambda tf-init tf-apply

package-lambda:
	cd lambda && zip -r lambda.zip start_workflow_lambda.py

tf-init:
	cd terraform && terraform init

tf-apply: package-lambda tf-init
	cd terraform && terraform apply -auto-approve -var="bucket_name=your-unique-bucket-name" -var="prefix=demo"
```

---

# 8) README / Steps to deploy

1. Put the files into directories as described:

    - `terraform/` (with `main.tf`, `variables.tf`, `glue_assume_role_policy.json`)
    - `glue/scripts/job1_etl.py`, `glue/scripts/job2_etl.py`
    - `lambda/start_workflow_lambda.py`
    - `Makefile` at repo root

2. Edit Glue scripts: replace `<<REPLACE_BUCKET>>` with the `bucket_name` you plan to use (or better — parameterize using Glue job arguments).

3. Build the lambda zip:

    ```bash
    make package-lambda
    ```

4. Initialize & apply Terraform:

    ```bash
    cd terraform
    terraform init
    terraform apply -var="bucket_name=your-globally-unique-bucket-name" -auto-approve
    ```

    Terraform will create the bucket, upload script files and lambda zip, create IAM roles, two Glue jobs, a Glue workflow and two triggers, and a Lambda wired to EventBridge S3 object-created events.

5. Test:

    - Upload a small CSV to `s3://<bucket>/raw/` (for example `raw/test1.csv`).
    - EventBridge will trigger Lambda which calls `glue.start_workflow_run(Name=<workflow>)`.
    - The workflow will start — `trigger_job1` will launch `job1`. When `job1` SUCCEEDS, `trigger_after_job1` will launch `job2`.
    - Inspect Glue console > Workflows / Jobs to see runs and details, check S3 for `staging/` and `processed/` outputs.

6. Cleanup:

    ```bash
    terraform destroy -var="bucket_name=your-globally-unique-bucket-name" -auto-approve
    ```

    (Because `force_destroy = true` on the bucket, the bucket and objects will be removed by TF; remove that in prod.)

---

## How the Glue Workflow & Triggers work (concise explanation)

-   **Glue Workflow** is a named container for a run instance (a DAG). You **start** a workflow run (API `StartWorkflowRun`) and the workflow engine drives its internal triggers and actions. Terraform `aws_glue_workflow` creates the workflow entity. ([registry.terraform.io][1])
-   **Glue Trigger types**:

    -   `ON_DEMAND`: can be invoked by API (or associated to start when workflow run starts) to execute the configured action(s). In our pattern we set an `ON_DEMAND` trigger with `workflow_name` so it becomes the entry node when the workflow run starts. ([registry.terraform.io][4])
    -   `CONDITIONAL`: evaluates specified predicate conditions (job success/failure etc.) and runs actions when conditions are met — used to chain jobs inside the workflow. ([registry.terraform.io][4])
    -   `SCHEDULED`: runs on cron schedule — not used in this demo but supported.

-   **Starting workflows**: `boto3.client('glue').start_workflow_run(Name='...')` starts a workflow run and returns a `RunId`. We use Lambda for that step, invoked by S3 object-created event. Example usage is common and well-documented. ([Stack Overflow][3])

---

## References / further reading

-   Terraform `aws_glue_workflow` & `aws_glue_trigger` docs (resource examples & syntax). ([registry.terraform.io][1])
-   Terraform `aws_glue_job` docs (job configuration & script_location). ([registry.terraform.io][5])
-   Example pattern: S3 -> Lambda -> Glue Workflow (serverless pattern). ([Serverless Land][6])

---

## Optional improvements & production considerations

-   Use parameterized Glue job arguments instead of hard-coded S3 paths.
-   Use KMS for bucket encryption, set `server_side_encryption_configuration`.
-   Use least-privilege IAM policies (limit ARNs instead of `"*"`).
-   Add CloudWatch alarms and Glue job logging configuration, send logs to centralized account.
-   Implement CI/CD to build Lambda zip and upload Glue scripts automatically (e.g., GitHub Actions or CodePipeline).
-   If you need to pass the S3 key/bucket from the initial event into the workflow and to jobs, consider using the Glue `StartWorkflowRun` `RunProperties` parameter (you can pass key/value map) and then read run properties inside jobs via `getResolvedOptions` / Glue job arguments.

---

## Quick notes about limits / gotchas

-   When your Glue job scripts are large or require dependencies, you’ll need to package extra Python files and set `--extra-py-files` or publish a wheel to S3 and reference it via `extra_python_libs` or use Glue Python shell / Glue Container image. Glue has specific ways to include extra packages — see Glue docs for `--extra-py-files` and Glue Python/multi-package support. ([registry.terraform.io][5])
-   Terraform `aws_glue_trigger` can be tricky when generating variable counts of triggers/actions — if you plan to generate triggers programmatically, look into Terraform `for_each` patterns (community posts discuss patterns). ([HashiCorp Discuss][7])
