
# The `nvm use` command is used with Node Version Manager (nvm) to switch to a specific version of Node.js that you have installed using nvm. This command allows you to select a specific Node.js version from your installed versions and set it as the currently active version.
nvm use
npm init
npm install aws-sdk --save


#=============================================================================
#=============================================================================

# terraform resources
chmod +x main.tf
./main.tf apply

# put file on S3 with the nonmatching metadata
aws --profile some-aws-profile s3 cp example.csv s3://some-s3-bucket/some-path/ --metadata '{"filter-by":"wrong filter value"}'

# attempt to receive SQS messages
AWS_PROFILE=some-aws-profile AWS_REGION=us-east-1 AWS_ACCOUNT_ID=some-aws-account-id SQS_QUEUE_NAME=some-sqs-queue-name node sqs-client.js
# no results

# puts file on S3 with matching metadata
aws --profile some-aws-profile s3 cp example.csv s3://some-s3-bucket/some-path/ --metadata '{"filter-by":"this-filter-value"}'

# attempt to receive filteres SQS message:
AWS_PROFILE=some-aws-profile AWS_REGION=us-east-1 AWS_ACCOUNT_ID=some-aws-account-id SQS_QUEUE_NAME=some-sqs-queue-name node sqs-client.js

# successful output:
messageAttributes {
  "object_key": {
    "Type": "String",
    "Value": "some-path/example.csv"
  },
  "bucket_name": {
    "Type": "String",
    "Value": "some-s3-bucket"
  },
  "filter-by": {
    "Type": "String",
    "Value": "this-filter-value"
  }
}