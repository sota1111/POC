import json
import base64
import boto3

def lambda_handler(event, context):
    print(f"call upload:")
    try:
        # データをJSONとしてパース
        body = json.loads(event['body'])
        
        file_data_b64 = body.get('file_data', '')
        file_data = base64.b64decode(file_data_b64)
        file_name = body.get('file_name', 'unknown.csv')

        
        print(f"call upload:{file_name}")

        # S3クライアントを初期化
        s3 = boto3.client('s3')

        # S3にファイルをアップロード
        bucket_name = 'log-robot-data'  # 自分のS3バケット名に変更してください
        s3.put_object(Body=file_data, Bucket=bucket_name, Key=file_name)

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({
                "message": "File uploaded successfully",
            }),
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({
                "message": f"Failed to upload file: {str(e)}",
            }),
        }
