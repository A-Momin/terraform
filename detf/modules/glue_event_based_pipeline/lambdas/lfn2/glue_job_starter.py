import json
import boto3
import os

GLUE_JOB_NAME = os.environ["GLUE_JOB_NAME"]


def job_starter_handler(event, context):
    glue=boto3.client('glue')

    print(event)
    print("Invoking Glue Job:", GLUE_JOB_NAME)
    args = event

    glue.start_job_run(JobName=GLUE_JOB_NAME, Arguments=args)
 