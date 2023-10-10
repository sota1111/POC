# 必要なモジュールをインポートします
import pandas as pd
import matplotlib.pyplot as plt
import io
import os

# データフレームのフィルタリングと数値変換
def filter_imu_rows(df):
    if 'IMU' in df.columns:
        df = df[(df['IMU'] == " IMU") | (df['IMU'] == " GYRO")]
    return df

def convert_columns_to_numeric(df):
    for col in df.columns:
        if df[col].dtype == 'object':
            df[col] = pd.to_numeric(df[col], errors='coerce')
    return df

# プロットの生成と保存
def plot_and_save(df, file_name):
    all_columns_to_plot = [
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
            except KeyError:
                print(f"Warning: Column {col} is missing. Skipping this column.")
            except Exception as e:
                print(f"An unexpected error occurred while plotting {col}: {e}. Skipping this column.")

    for i in range(len(all_columns_to_plot), len(axes)):
        fig.delaxes(axes[i])

    plt.tight_layout(rect=[0, 0.03, 1, 0.97])
    
    png_file_name = os.path.splitext(file_name)[0] + '.png'
    png_file_path = f'{png_file_name}'
    fig.savefig(png_file_path)
    
    return png_file_path


def main():
    file_path = './20231009221821_13回目.csv'
    file_name = os.path.basename(file_path)
    with open(file_path, 'rb') as f:
        file_data = f.read()

    # カラムヘッダーを追加します
    header_to_add = "AD,AD1,AD2,AD3,AD4,AD5,AD6,AD7,AD8,FLOW,FLOW1,FLOW2,MOT,MOT1,MOT2,BLK1,BLK2"
    df = pd.read_csv(io.BytesIO(file_data), header=None, engine='python', on_bad_lines='skip')
    lines = io.StringIO(file_data.decode('utf-8')).readlines()
    updated_first_line = f"{lines[0].strip()},{header_to_add}"
    lines[0] = updated_first_line
    updated_file_data = '\n'.join(lines).encode('utf-8')




    df = pd.read_csv(io.BytesIO(updated_file_data), on_bad_lines='skip')
    df = filter_imu_rows(df)
    df = convert_columns_to_numeric(df)
    file_name_png = plot_and_save(df, file_name)

if __name__ == "__main__":
    main()
