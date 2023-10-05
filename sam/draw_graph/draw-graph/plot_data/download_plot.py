import json
import boto3
import base64
import os

def get_experiment_data_from_dynamodb(experiment_date, experiment_number):
    dynamodb = boto3.resource('dynamodb')
    db = dynamodb.Table('experiment')
    db_response = db.get_item(
        Key={
            'Date': experiment_date,
            'OrderID': experiment_number
        }
    )
    return db_response.get('Item', {})

# 既存の関数
def fetch_s3_object(bucket_name, file_key):
    if not file_key:
        return None
    s3 = boto3.client('s3')
    return s3.get_object(Bucket=bucket_name, Key=file_key)['Body'].read()

# 既存の関数
def to_base64_encoded(content):
    if content is None:
        return None
    return base64.b64encode(content).decode('utf-8')

# 既存の関数
def get_content_type(file_path):
    if file_path is None:
        return None
    file_extension = os.path.splitext(file_path)[1][1:]
    return f"image/{file_extension}"

def lambda_handler(event, context):
    try:
        # Parse request data
        body = json.loads(event['body'])
        experiment_date = body.get('experiment_date', '2023-10-3')
        experiment_number = int(body.get('experiment_number', '0'))
        
        # Fetch experiment data from DynamoDB
        item = get_experiment_data_from_dynamodb(experiment_date, experiment_number)
        log_png = item.get('log_png', '')
        trajectory = item.get('trajectory', '')
        continuous = item.get('continuous', '')
        
        # Fetch files from S3
        bucket_name = 'log-robot-data'
        content_log = fetch_s3_object(bucket_name, f"{experiment_date}/{experiment_number}/{log_png}")
        content_tra = fetch_s3_object(bucket_name, f"{experiment_date}/{experiment_number}/{trajectory}")
        content_con = fetch_s3_object(bucket_name, f"{experiment_date}/{experiment_number}/{continuous}")

        # Encode files to Base64
        base64_encoded_log = to_base64_encoded(content_log)
        base64_encoded_tra = to_base64_encoded(content_tra)
        base64_encoded_con = to_base64_encoded(content_con)
        
        # Determine content types
        content_type_tra = get_content_type(trajectory)
        content_type_con = get_content_type(continuous)
        
        # Build response
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "File downloaded successfully",
                "data_log": base64_encoded_log,
                "type": "image/png",
                "data_trajectory": base64_encoded_tra,
                "type": content_type_tra,
                "data_continuous": base64_encoded_con,
                "type": content_type_con,
            }),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": f"Failed to download file: {str(e)}"
            }),
        }
