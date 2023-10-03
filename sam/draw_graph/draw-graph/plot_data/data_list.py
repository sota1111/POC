import json
import boto3
from botocore.exceptions import ClientError
from config import TABLE_NAME, INDEX_NAME, INDEX_KEY_NAME1
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
    try:
        body = json.loads(event['body'])
        experiment_date = body.get('experiment_date', '2023-1-1')
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(TABLE_NAME)

        items = get_date_items(table, INDEX_NAME, experiment_date)

        # JSONレスポンスを作成
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "data": items,
                "message": "Plot created successfully",
            }, default=decimal_to_str),
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
