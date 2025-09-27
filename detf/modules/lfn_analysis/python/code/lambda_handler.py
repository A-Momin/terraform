from datetime import datetime
import json
import boto3
from jinja2 import Template
import os
import traceback
from mylogger import CustomLogger

logger = CustomLogger()

# EFS mount path
EFS_PATH = "/mnt/efs"

# Recipient emails or domains in the AWS Email Sandbox must be verified
FROM_ADDRESS = 'AMominNJ@gmail.com'
REPLY_TO_ADDRESS = 'AMominNJ@gmail.com'
TEMPLATE_S3_BUCKET = "gpc-cuckoo-bucket-htech"

CLIENTS = [
    {
        # You'll need to verify this email which is case-sensitive
        "email": "bbcredcap3@gmail.com",
        "first_name": "AMINUL",
        "last_name": "MOMIN",
        "pet_name": "Montu",
    },
]

EMPLOYEES = [
    {
        # You'll need to verify this email
        'email': 'A.Momin.NYC@gmail.com',
        'first_name': 'Homer',
        'last_name': 'Simpson'
    },
]

def save_to_efs(content: str):
    """
    Save processed content to EFS with timestamped filename.
    """
    filename = os.path.join(EFS_PATH, "aws_efs_testing.txt",)
    try:
        with open(filename, "w") as f:
            f.write(content)
            f.write("\n")
    except Exception as e:
        logger.error(e)
    else:
        logger.info(f"Data has been saved in EFS ({filename})")
    
    with open(filename, "r") as f:
        efs_data = f.read()
    
    return efs_data

def get_template_from_s3(key):
    """Loads and returns html template from Amazon S3"""
    s3 = boto3.client('s3')
    s3_file = s3.get_object(Bucket=TEMPLATE_S3_BUCKET, Key=key)

    try:
        template = Template(s3_file['Body'].read().decode('utf-8'))
    except Exception as e:
        logger.eror('Failed to load template')
        raise e
    else:
        logger.info(f"Template ({key}) has been obtained")

    return template

def render_come_to_work_template(employee_first_name):
    template = get_template_from_s3("email-templates/come_to_work.html")
    html_email = template.render(first_name = employee_first_name)
    plaintext_email = 'Hello {0}, \nPlease remember to be into work by 8am'.format(employee_first_name)
    return html_email, plaintext_email

def render_daily_tasks_template():
    template = get_template_from_s3("email-templates/daily_tasks.html")
    tasks = {
        'Monday': '- Clean the dog areas\n',
        'Tuesday': '- Clean the cat areas\n',
        'Wednesday': '- Feed the aligator\n',
        'Thursday': '- Clean the dog areas\n',
        'Friday': '- Clean the cat areas\n',
        'Saturday': '- Relax! Play with the puppies! It\'s the weekend!',
        'Sunday': '- Relax! Play with the puppies! It\'s the weekend!'
    }
    # Gets an integer value from 0 to 6 for today (Monday - Sunday)
    # Keep in mind this will run in GMT and you will need to adjust runtimes accordingly 
    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    today = days[datetime.today().weekday()]
    html_email = template.render(
        day_of_week=today, 
        daily_tasks=tasks[today]
    )
    plaintext_email = (
        "Remember to do all of these today:\n"
        "- Feed the dogs\n"
        "- Feed the rabbits\n"
        "- Feed the cats\n"
        "- Feed the turtles\n"
        "- Walk the dogs\n"
        "- Empty cat litterboxes\n"
        "{0}".format(tasks[today])
    )
    return html_email, plaintext_email

def render_pickup_template(client_first_name, client_pet_name):
    template = get_template_from_s3("email-templates/pickup.html")
    html_email = template.render(first_name=client_first_name, pet_name = client_pet_name)
    plaintext_email = (
        'Hello {0}, \nPlease remember to '
        'pickup {1} by 7pm!'.format(client_first_name, client_pet_name)
    )
    return html_email, plaintext_email

def send_email(html_email, plaintext_email, subject, recipients):
    try:
        ses = boto3.client('ses')

        ses.send_email(
            Source=FROM_ADDRESS,
            Destination={'ToAddresses': [recipients], 'CcAddresses': [], 'BccAddresses': []},
            Message={
                'Subject': { 'Data': subject,},
                'Body': {
                    'Text': {'Data': plaintext_email},
                    'Html': {'Data': html_email}
                }
            },
            ReplyToAddresses=[REPLY_TO_ADDRESS,]
        )
        logger.info(f"Email has been sent to {recipients}")

    except Exception as e:
        logger.info('Failed to send message via SES')
        logger.error(e)
        raise e

def cuckoo_handler(event, context):
    s3_client = boto3.client("s3", region_name = os.environ["AWS_DEFAULT_RGION"])

    logger.info(f"Event sent to {__name__}:\n")
    logger.info(event)

    handler_info = f"""
    ################################################
    FUNCTION_NAME = {context.function_name}\n
    CURRENT_TIME = {datetime.now()}
    ################################################\n\n
    """

    try:
        efs_data = save_to_efs(handler_info)
    except Exception as e:
        logger.error(e)
    else:
        logger.info(efs_data)

    try:
        efs_data_file = os.path.join(EFS_PATH, "aws_efs_testing.txt")
        logger.info(f"Uploading file: {efs_data_file} to bucket: {TEMPLATE_S3_BUCKET}")
        
        # Ensure file exists before upload
        if not os.path.exists(efs_data_file):
            raise FileNotFoundError(f"{efs_data_file} does not exist in EFS")

        s3_client.upload_file(
            Filename=efs_data_file,
            Bucket=TEMPLATE_S3_BUCKET,
            Key="AWS-EFS-Data/aws_efs_testing.txt"
        )

    except Exception as e:
        logger.exception("Error uploading EFS file to S3")
    else:
        logger.info("✅ EFS data has been uploaded into S3 Bucket (AWS-EFS-Data)")

    event_trigger = event['resources'][0]
    logger.info('event triggered by ' + event_trigger)

    if 'come_to_work' in event_trigger:
        for employee in EMPLOYEES:
            html_email, plaintext_email = render_come_to_work_template(employee['first_name'])
            send_email(html_email, plaintext_email, 'Work Schedule Reminder', employee['email'])
            # return {"body": json.dumps(plaintext_email)}

    elif 'daily_tasks' in event_trigger:
        for employee in EMPLOYEES:
            html_email, plaintext_email = render_daily_tasks_template()
            send_email(html_email, plaintext_email, 'Daily Tasks Reminder', employee['email'])
            # return {"body": json.dumps(plaintext_email)}

    elif 'pickup' in event_trigger:
        for client in CLIENTS:
            html_email, plaintext_email = render_pickup_template(client['first_name'], client['pet_name'])
            send_email(html_email, plaintext_email, 'Pickup Reminder', client['email'])
            # return {"body": json.dumps(plaintext_email)}
    else:
        return 'No template for this trigger!'


###############################################################################
############################## SQS Processor ##################################
###############################################################################

# Initialize AWS clients
sqs_client = boto3.client("sqs")
sns_client = boto3.client("sns")

# Environment variables
INPUT_QUEUE_URL = os.environ.get("INPUT_QUEUE_URL")
FAILURE_QUEUE_URL = os.environ.get("FAILURE_QUEUE_URL")
SUCCESS_TOPIC_ARN = os.environ.get("SUCCESS_TOPIC_ARN")


def process_message(message_body: str) -> str:
    """
    Process the message logic.
    Replace this with your actual processing code.
    """
    # Example: Just reversing the string
    return message_body[::-1]

def sqs_processor_handler(event, context):
    """
    AWS Lambda handler for SQS messages.
    Success/Failure routing handled by Lambda Destinations.
    """

    logger.info(f"Event sent to {__name__}:\n")
    logger.info(event)

    handler_info = f"""
    ################################################
    CURRENT_TIME = {datetime.now()}\n
    FUNCTION_NAME = {context.function_name}\n
    FUNCTION_VERSION = {context.function_version}\n
    INVOKED_ARN = {context.invoked_function_arn}\n
    REQUEST_ID = {context.aws_request_id}\n
    ################################################\n\n
    """

    logger.info("Saving data into EFS")
    efs_data = save_to_efs(handler_info)
    logger.info(efs_data)


    results = []

    for record in event["Records"]:
        message_id = record["messageId"]
        body = record["body"]

        try:
            logger.info(f"Processing message with Message_ID={message_id}:\n \t{body}")

            # Step 1: Process message
            result = process_message(body)

            # Step 2: Save to EFS
            save_to_efs(result)

            # Append success result
            results.append(
                {"messageId": message_id, "status": "success", "result": result}
            )

        except Exception as e:
            logger.info(f"Error processing message {message_id}")
            logger.error(f"{str(e)}")
            traceback.logger.info_exc()

            # Append failure result
            results.append(
                {
                    "messageId": message_id,
                    "status": "failure",
                    "error": str(e),
                    "stacktrace": traceback.format_exc(),
                    "original_body": body,
                }
            )
            # Raise exception to trigger Lambda destination "on_failure"
            raise

    # Returning success triggers Lambda destination "on_success"
    return {"statusCode": 200, "body": json.dumps(results)}