import json
import os
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

######################################################################################################
## The code is not getting loaded from S3 Bucket !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
######################################################################################################

# GLUE_WORKFLOW_NAME = os.environ.get("GLUE_WORKFLOW_NAME", "GWF-glue-workflow")  # set via TF or console

glue = boto3.client("glue")


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    print(event)

    # Start the Glue workflow
    try:
        resp = glue.start_workflow_run(Name=event["GLUE_WORKFLOW_NAME"])
        logger.info("Started workflow %s run id=%s", event["GLUE_WORKFLOW_NAME"], resp.get("RunId"))
        return {"statusCode": 200, "body": json.dumps({"runId": resp.get("RunId")})}
    except Exception:
        logger.exception("Failed to start Glue workflow")
        raise
