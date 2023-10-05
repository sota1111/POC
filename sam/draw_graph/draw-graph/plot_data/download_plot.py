import json
import boto3
import base64
import os

def lambda_handler(event, context):
    print(f"call download_plot")
    try:
        # DynamoDBの設定
        dynamodb = boto3.resource('dynamodb')
        db = dynamodb.Table('experiment')
        
        # データをJSONとしてパース
        body = json.loads(event['body'])
        experiment_date = body.get('experiment_date', '2023-10-3')
        print(f"experiment_date:{experiment_date}")
        experiment_number = int(body.get('experiment_number', '0'))
        print(f"experiment_number:{experiment_number}")

        # DynamoDBから必要なデータを取得
        db_response = db.get_item(
            Key={
                'Date': experiment_date,
                'OrderID': experiment_number
            }
        )
        item = db_response.get('Item', {})
        print(f"db item:{item}")
        log_png = item.get('log_png', '')
        trajectory = item.get('trajectory', '')
        continuous = item.get('continuous', '')

        s3 = boto3.client('s3')
        bucket_name = 'log-robot-data'  # バケット名を指定
        # Construct the file key dynamically based on experiment_date and experiment_number
        file_key_log = f"{experiment_date}/{experiment_number}/{log_png}"
        file_key_tra = f"{experiment_date}/{experiment_number}/{trajectory}"
        file_key_con = f"{experiment_date}/{experiment_number}/{continuous}"
        s3_object_log = s3.get_object(Bucket=bucket_name, Key=file_key_log)
        s3_object_tra = s3.get_object(Bucket=bucket_name, Key=file_key_tra)
        s3_object_con= s3.get_object(Bucket=bucket_name, Key=file_key_con)
        content_log = s3_object_log['Body'].read()
        content_tra = s3_object_tra['Body'].read()
        content_con = s3_object_con['Body'].read()
        
        # バイトデータをBase64エンコーディング
        base64_encoded_log = base64.b64encode(content_log).decode('utf-8')
        base64_encoded_tra = base64.b64encode(content_tra).decode('utf-8')
        base64_encoded_con = base64.b64encode(content_con).decode('utf-8')

        file_extension_tra = os.path.splitext(trajectory)[1][1:]
        content_type_tra = f"image/{file_extension_tra}" 
        file_extension_con = os.path.splitext(continuous)[1][1:] 
        content_type_con = f"image/{file_extension_con}" 
        
        # JSONレスポンスを作成
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
        print(f"Exception: {str(e)}")
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
