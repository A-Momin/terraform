In this post, I’ll share some Terraform code which provisions a AWS S3 bucket for file uploads, a S3 bucket notification to trigger an AWS Lambda NodeJS script to fetch S3 metadata and push to a AWS SNS topic, and a AWS SQS queue with a filtered topic subscription. This can be useful if you need S3 bucket notifications to fanout to different SQS queues based on the S3 metadata or path.

### s3-lambda-sns-sqs-terraform | [See blog post here](http://ericlondon.com/2018/09/23/terraforming-s3-bucket-notification-aws-nodejs-lambda-to-fetch-metadata-sns-publishing-and-filtered-sqs-subscription-policy.html)

-   Terraforming S3 bucket notification
-   AWS NodeJS Lambda to fetch metadata
-   SNS publishing
-   filtered SQS subscription policy
