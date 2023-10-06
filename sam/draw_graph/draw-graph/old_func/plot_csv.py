import pandas as pd
import matplotlib.pyplot as plt
import json
import boto3
import io

def lambda_handler(event, context):
    print(f"call plot")
    try:
        # ここでは仮にCSVデータがS3から取得されるとします。
        # s3_client = boto3.client('s3')
        # csv_file = s3_client.get_object(Bucket='your-bucket', Key='your-key')['Body']
        # df = pd.read_csv(csv_file)
        
        # テスト用に仮のデータフレームを作成
        df = pd.DataFrame({
            'x': [1, 2, 3, 4, 5],
            'y': [1, 4, 9, 16, 25]
        })

        # データをプロット
        fig, ax = plt.subplots(figsize=(10, 6))  # この行でfigureとaxesオブジェクトを作成します。
        ax.plot(df['x'], df['y'], marker='o')
        ax.set_title('Sample Plot')
        ax.set_xlabel('X-axis')
        ax.set_ylabel('Y-axis')
        ax.grid(True)

        print(f"finish plot")

        # プロットをバイトデータとして保存
        fig.savefig('/tmp/sample.png')
        client = boto3.client('s3')
        bucket_name = 'log-robot-data'
        client.upload_file(
            '/tmp/sample.png',
            bucket_name,
            'sample.png'
        )

        print(f"call upload to S3")

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({
                "message": "Plot created successfully",
            }),
        }
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({
                "message": f"Failed to create plot: {str(e)}",
            }),
        }
