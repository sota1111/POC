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

def filter_imu_rows(df):
    if 'IMU' in df.columns:
        df = df[(df['IMU'] == " IMU") | (df['IMU'] == " GYRO")]
    return df

def convert_columns_to_numeric(df):
    for col in df.columns:
        if df[col].dtype == 'object':
            df[col] = pd.to_numeric(df[col], errors='coerce')
    return df


def plot_and_save(df, file_name):
    all_columns_to_plot = all_columns_to_plot = [
        'AccX', 'AccY', 'AccZ', 'MagX', 'MagY', 'MagZ', 'GyrX', 'GyrY', 'GyrZ',
        'Head', 'Roll', 'Pitch', 'QuaW', 'QuaX', 'QuaY', 'QuaZ', 'LiaX', 'LiaY',
        'LiaZ', 'GrvX', 'GrvY', 'GrvZ', 'FLOW1', 'FLOW2', 'MOT1', 'MOT2', 'BLK1', 'BLK2'
    ]
    
    fig, axes = plt.subplots(nrows=7, ncols=4, figsize=(20, 35))
    fig.suptitle('Time Series Plots of All Relevant Gyro Sensor Data')

    axes = axes.flatten()
    for i, col in enumerate(all_columns_to_plot):
        if col in df.columns:
            try:
                axes[i].plot(df['Time'], df[col], label=col)
                axes[i].set_title(f'{col}')
                axes[i].set_xlabel('Time')
                axes[i].set_ylabel(col)
                axes[i].grid(True)

                # Adding FLOW2 on the second y-axis
                if 'FLOW2' in df.columns:
                    ax2 = axes[i].twinx()
                    ax2.plot(df['Time'], df['FLOW2'], 'r--', label='FLOW2')
                    ax2.set_ylabel('FLOW2')

            except KeyError:
                print(f"Warning: Column {col} is missing. Skipping this column.")
            except Exception as e:
                print(f"An unexpected error occurred while plotting {col}: {e}. Skipping this column.")

    for i in range(len(all_columns_to_plot), len(axes)):
        fig.delaxes(axes[i])

    plt.tight_layout(rect=[0, 0.03, 1, 0.97])
    
    png_file_name = os.path.splitext(file_name)[0] + '.png'
    fig.savefig(f'/tmp/{png_file_name}')
    
    return png_file_name

def plot_selected_columns(df_filtered, file_name):
    fig, axes = plt.subplots(2, 1, figsize=(10, 12))
    axes = axes.flatten()

    selected_sets = [
        {'primary': [('FLOW2', 'orange'), ('MOT2', 'g')], 'secondary': [('GrvX', 'b')]},
        {'primary': [('FLOW2', 'orange'), ('MOT2', 'g')], 'secondary': [('Pitch', 'b')]}
    ]

    for i, selected in enumerate(selected_sets):
        ax1 = axes[i]
        ax2 = ax1.twinx()

        ax1.grid(True, which='major', axis='both')

        # x軸にマイナーグリッドを適用
        ax1.minorticks_on()
        ax1.xaxis.grid(which='minor', linestyle='-.', linewidth='0.5', color='grey')

        for col, col_color in selected['primary']:
            if col in df_filtered.columns:
                ax1.plot(df_filtered['Time'], df_filtered[col], label=f'{col} (left axis)', color=col_color)

        for col, col_color in selected['secondary']:
            if col in df_filtered.columns:
                ax2.plot(df_filtered['Time'], df_filtered[col], label=f'{col} (right axis)', color=col_color, linestyle='--')

        ax1.set_xlabel('Time(us)')

        #custom_labels = ['モータON', 'モータ 100%', '', '加速', '走行', 'ジャンプ', 'ブレーキON待ち', 'ブレーキON', '回転抑制待ち', '回転抑制中', 'モータフリー']
        custom_labels = ['Motor Off', 'Motor 100%', '', 'Accelerating', 'Running', 'Jumping', 'Waiting for Brake ON', 'Brake ON', 'Waiting for Rotation Suppression', 'Rotation Suppression Active', 'Motor Free']
        ax1.set_yticks(range(0, 11))
        ax1.set_yticklabels(custom_labels)

        lines, labels = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax2.legend(lines + lines2, labels + labels2, loc='upper left')

    plt.tight_layout()


    png_file_name = os.path.splitext(file_name)[0] + '_selected_columns.png'
    fig.savefig(f'/tmp/{png_file_name}')
    
    return png_file_name

# itemを追加する
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
    

def put_or_update_item(table, item):
    print("□ add_date_item")
    try:
        print(f"table:{table}")
        
        # パーティションキーとソートキーで検索
        response = table.get_item(
            Key={
                'Date': item['Date'],
                'OrderID': item['OrderID']
            }
        )
        
        # 既存のアイテムがあればupdate_itemを呼び出す
        if 'Item' in response:
            update_expression = "SET "
            expression_attribute_values = {}
            
            for key, value in item.items():
                if key not in ['Date', 'OrderID']:
                    if key == 'Message' and value == "":
                        print(f"value:{value}")
                        continue
                    update_expression += f"{key} = :{key}, "
                    expression_attribute_values[f":{key}"] = value
            
            update_expression = update_expression.rstrip(', ')
            
            table.update_item(
                Key={
                    'Date': item['Date'],
                    'OrderID': item['OrderID']
                },
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_attribute_values
            )
            return f"Item with Date {item['Date']} and OrderID {item['OrderID']} has been updated."
        
        # 既存のアイテムがなければput_itemを呼び出す
        else:
            table.put_item(Item=item)
            return f"Item with Date {item['Date']} and OrderID {item['OrderID']} has been added."

    except ClientError as e:
        raise ClientError(e.response["Error"]["Message"])
    except Exception as e:
        raise Exception(str(e))

    
def upload_to_s3_with_date(s3, file_data, bucket_name, file_name, date, number):
    s3_key = f"{date}/{number}/{file_name}"
    s3.put_object(Body=file_data, Bucket=bucket_name, Key=s3_key)
    print(f"uploaded to {s3_key}")
    return s3_key

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
        message = body.get('message', '')
        file_type = body.get('file_type', '')
        print(f"file_type:{file_type}")
        
        # S3クライアントを初期化
        s3 = boto3.client('s3')
        db = boto3.resource('dynamodb')
        table = db.Table('experiment')
        bucket_name = 'log-robot-data'


        if file_type == 'log':
            upload_to_s3_with_date(s3, file_data, bucket_name, file_name, experiment_date, experiment_number)
            header_to_add = "AD,AD1,AD2,AD3,AD4,AD5,AD6,AD7,AD8,FLOW,FLOW1,FLOW2,MOT,MOT1,MOT2,BLK1,BLK2"
            df = pd.read_csv(io.BytesIO(file_data), header=None, engine='python', on_bad_lines='skip')
            lines = io.StringIO(file_data.decode('utf-8')).readlines()

            num_existing_columns = len(lines[0].split(','))
            num_columns_to_add = len(header_to_add.split(','))

            if num_existing_columns != num_columns_to_add:
                updated_first_line = f"{lines[0].strip()},{header_to_add}"
                lines[0] = updated_first_line
                updated_file_data = '\n'.join(lines).encode('utf-8')
                df = pd.read_csv(io.BytesIO(updated_file_data), on_bad_lines='skip')
                #upload_to_s3_with_date(s3, updated_file_data, bucket_name, file_name, experiment_date, experiment_number)
            print(f"uploaded csv:{file_name}")

            # プロット
            df = filter_imu_rows(df)
            df = convert_columns_to_numeric(df)
            df = df[df['FLOW2'] <= 10]
            file_name_png = plot_and_save(df, file_name)
            df = df[df['FLOW2'] >= 5]
            selected_columns_png = plot_selected_columns(df, file_name)
            print(f"finish plot")

            # S3にpngファイルをアップロード
            s3_key_png = f"{experiment_date}/{experiment_number}/{file_name_png}"
            s3.upload_file(f'/tmp/{file_name_png}', bucket_name, s3_key_png)
            s3_key_png = f"{experiment_date}/{experiment_number}/{selected_columns_png}"
            s3.upload_file(f'/tmp/{selected_columns_png}', bucket_name, s3_key_png)

            item = {
                    'Date': experiment_date,
                    'OrderID': int(experiment_number),
                    'log_csv': file_name,
                    'log_png': selected_columns_png,
                    'continuous': file_name_png,
                    'Message': message,
                }
            print(f"post_item: {item}")
            put_or_update_item(table, item)

        elif file_type == 'trajectory':
            upload_to_s3_with_date(s3, file_data, bucket_name, file_name, experiment_date, experiment_number)

            item = {
                    'Date': experiment_date,
                    'OrderID': int(experiment_number),
                    'trajectory': file_name,
                    'Message': message,
                }
            print(f"post_item: {item}")
            put_or_update_item(table, item)

        elif file_type == 'continuous':
            upload_to_s3_with_date(s3, file_data, bucket_name, file_name, experiment_date, experiment_number)

            item = {
                    'Date': experiment_date,
                    'OrderID': int(experiment_number),
                    'continuous': file_name,
                    'Message': message,
                }
            print(f"post_item: {item}")
            put_or_update_item(table, item)

        else:
            return {
                "statusCode": 400,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                },
                "body": json.dumps({
                    "message": "file type is not supported",
                }),
            }


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
