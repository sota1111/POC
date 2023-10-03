import io
import json
import base64
import boto3
import pandas as pd
import matplotlib.pyplot as plt
import os  # osライブラリを追加


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

def lambda_handler(event, context):
    print(f"call upload")
    try:
        # データをJSONとしてパース
        body = json.loads(event['body'])
        file_data_b64 = body.get('file_data', '')
        file_data = base64.b64decode(file_data_b64)
        file_name = body.get('file_name', 'unknown.csv')
        experiment_date = body.get('experiment_date', '2023-10-3')
        experiment_number = body.get('experiment_number', '0')
        message = body.get('message', 'hello')
        print(f"call upload:{file_name}")

        # S3クライアントを初期化
        s3 = boto3.client('s3')

        # S3にcsvファイルをアップロード
        bucket_name = 'log-robot-data'
        s3.put_object(Body=file_data, Bucket=bucket_name, Key=file_name)
        print(f"uploaded csv:{file_name}")

        # プロット
        df = pd.read_csv(io.BytesIO(file_data))
        png_file_name = plot_and_save(df, file_name)
        print(f"finish plot")

        # S3にpngファイルをアップロード
        s3.upload_file(f'/tmp/{png_file_name}', bucket_name, png_file_name)

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
