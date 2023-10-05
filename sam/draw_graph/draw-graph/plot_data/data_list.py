import json
import boto3
from botocore.exceptions import ClientError
from config import TABLE_NAME, INDEX_NAME, INDEX_KEY_NAME1, PARTITION_KEY_NAME, SORT_KEY_NAME
from decimal import Decimal

def decimal_to_str(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError

# ロギングの設定
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_date_items(table, index_name, index_key1):
    print("□ get_date_items")
    try:
        # DynamoDBの予約語を回避するための属性名マッピングを追加
        expression_attribute_names = {
            '#ikn1': INDEX_KEY_NAME1,
        }
        response = table.query(
            IndexName=index_name,
            KeyConditionExpression='#ikn1 = :ik1',
            ExpressionAttributeValues={
                ':ik1': index_key1,
            },
            ExpressionAttributeNames=expression_attribute_names
        )
        sorted_items = sorted(response['Items'], key=lambda x: x['OrderID'])
        return sorted_items
    except ClientError as e:
        raise ClientError(e.response["Error"]["Message"])
    except Exception as e:
        raise Exception(str(e))

    
def lambda_handler(event, context):
    print(f"call get list")
    http_method = event['httpMethod']
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(TABLE_NAME)
    body = json.loads(event['body'])

    try:
        date = body.get('experiment_date', '2023-1-1')

        if http_method == 'POST':
            print(f"call get list for POST")
            items = get_date_items(table, INDEX_NAME, date)
            return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                    "Content-Type": "application/json"
                },
                "body": json.dumps({
                    "data": items,
                    "message": "complete get method",
                }, default=decimal_to_str),
            }

        elif http_method == 'PUT':
            print(f"call get list for PUT")
            experiment_number = int(body.get('experiment_number', '0'))
            new_message = body.get('message', '')
            print(f"new_message:{new_message}")
            response = table.update_item(
                Key={
                    PARTITION_KEY_NAME: date,
                    SORT_KEY_NAME: experiment_number
                },
                UpdateExpression="SET #messageField = :messageVal",
                ExpressionAttributeNames={
                    "#messageField": "Message"
                },
                ExpressionAttributeValues={
                    ":messageVal": new_message
                },
                ReturnValues="ALL_NEW"  # 更新後の項目を戻り値として受け取る
            )
            return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                    "Content-Type": "application/json"
                },
                "body": json.dumps({
                    "message": "complete put method",
                }, default=decimal_to_str),
            }
        else:
            print(f"Fail response: {response}")
            return {
                "statusCode": 400,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                    "Content-Type": "application/json"
                },
                "body": json.dumps({
                    "message": "this method is not supported",
                }, default=decimal_to_str),
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
