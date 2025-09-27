import json
import boto3
import os

S3_CUSTOMER_CRAWLER_NAME = os.environ['S3_CUSTOMER_CRAWLER_NAME']

glue=boto3.client('glue')

def crawler_trigger_handler(event, context):

    print("="*50)
    print("Inputes The Lambda Function Received:\n")
    print(event)
    # print(json.dumps(event, indent=4)) 
    print("="*50)

    glue.start_crawler(Name=S3_CUSTOMER_CRAWLER_NAME)

    return {"statusCode": 200, "body": json.dumps(f"The Glue Crawler ({S3_CUSTOMER_CRAWLER_NAME}) has been started successfully.")}
