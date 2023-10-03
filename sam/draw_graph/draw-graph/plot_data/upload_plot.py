import io
import json
import base64
import boto3
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
import pandas as pd
import matplotlib.pyplot as plt
import os

# ロギングの設定
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def plot_and_save(df, file_name):
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(df['data_x'], df['data_y'], marker='o')
    ax.set_xlabel('time')
    ax.set_ylabel('data')
    ax.grid(True)
    print(f"Finish plot")
    
    png_file_name = os.path.splitext(file_name)[0] + '.png'
    fig.savefig(f'/tmp/{png_file_name}')
    
    return png_file_name

def add_date_item(table, item):
    print("□ add_date_item")
    try:
        print(f"table:{table}")
        response = table.put_item(Item=item)
        return "Item with Date {} and OrderID {} has been added.".format(item['Date'], item['OrderID'])
    except ClientError as e:
        raise ClientError(e.response["Error"]["Message"])
    except Exception as e:
        raise Exception(str(e))
    
# 既存のitemを上書きする
def update_one_item(self, partition_key, sort_key, update_expression, expression_values):
    print("□ update_one_item")
    try:
        response = self.table.update_item(
            Key={
                self.partition_key_name: partition_key,
                self.sort_key_name: sort_key
            },
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
            ReturnValues='UPDATED_NEW'
        )
        return "Item with partition key {} and sort key {} has been updated.".format(partition_key, sort_key)
    except ClientError as e:
        raise ClientError(e.response["Error"]["Message"])
    except Exception as e:
        raise Exception(str(e))

def lambda_handler(event, context):
    print(f"call upload")
    try:
        # データをJSONとしてパース
        body = json.loads(event['body'])
        file_data_b64 = body.get('file_data', '')
        file_data = base64.b64decode(file_data_b64)
        file_name = body.get('file_name', '')
        print(f"file_name:{file_name}")        
        experiment_date = body.get('experiment_date', '2023-10-3')
        print(f"experiment_date:{experiment_date}")
        experiment_number = body.get('experiment_number', '0')
        print(f"experiment_number:{experiment_number}")
        message = body.get('message', 'hello')
        
        _, file_extension = os.path.splitext(file_name)
        if file_extension == '.csv':
            file_name_csv = file_name
            # S3クライアントを初期化
            s3 = boto3.client('s3')
            db = boto3.resource('dynamodb')
            table = db.Table('experiment')

            # S3にcsvファイルをアップロード
            bucket_name = 'log-robot-data'
            s3.put_object(Body=file_data, Bucket=bucket_name, Key=file_name_csv)
            print(f"uploaded csv:{file_name_csv}")

            # プロット
            df = pd.read_csv(io.BytesIO(file_data))
            file_name_png = plot_and_save(df, file_name_csv)
            print(f"finish plot")

            # S3にpngファイルをアップロード
            s3.upload_file(f'/tmp/{file_name_png}', bucket_name, file_name_png)

            item = {
                    'Date': experiment_date,
                    'OrderID': int(experiment_number),
                    'Robot': "0",
                    'file_name_csv': file_name_csv,
                    'file_name_png': file_name_png,
                    'Message': message,
                }
            print(f"post_item: {item}")
            add_date_item(table, item)

            return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                },
                "body": json.dumps({
                    "message": "File uploaded successfully",
                }),
            }
        return {
            "statusCode": 400,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({
                "message": "File extension must be csv",
            }),
        }
        
    except Exception as e:
        print(f"Exception: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({
                "message": f"Failed to upload file: {str(e)}",
            }),
        }
