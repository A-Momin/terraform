import logging
import boto3
import os


def sqs_s3_handler(event, context):
    s3 = boto3.resource('s3')
    print(event)
    msg = event['Records'][0]["body"]
    file_name = f"""message_{event['Records'][0]["messageId"]}.json"""
    f = open("/tmp/msg.json", "w")
    f.write(msg)
    f.close()

    s3.meta.client.upload_file('/tmp/msg.json', 'httx-75243-sqs-s3-bucket', file_name)
