import json
import boto3
import base64

def lambda_handler(event, context):
    print(f"call download_plot")
    try:
        # データをJSONとしてパース
        body = json.loads(event['body'])
        experiment_date = body.get('experiment_date', '2023-10-3')
        print(f"experiment_date:{experiment_date}")
        experiment_number = body.get('experiment_number', '0')
        print(f"experiment_number:{experiment_number}")

        s3 = boto3.client('s3')
        bucket_name = 'log-robot-data'  # バケット名を指定
        file_key = 'sin_wave.png'  # ファイル名（キー）を指定
        
        # S3からファイルをダウンロード
        s3_response_object = s3.get_object(Bucket=bucket_name, Key=file_key)
        object_content = s3_response_object['Body'].read()
        
        # バイトデータをBase64エンコーディング
        base64_encoded_data = base64.b64encode(object_content).decode('utf-8')
        
        # JSONレスポンスを作成
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "File downloaded successfully",
                "data": base64_encoded_data,
                "type": "image/png"
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
