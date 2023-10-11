# 必要なモジュールをインポートします
import pandas as pd
import matplotlib.pyplot as plt
import io
import os
import matplotlib as mpl
# 日本語をサポートするフォントに設定
mpl.rcParams['font.family'] = 'Arial Unicode MS'

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
    png_file_path = f'{png_file_name}'
    fig.savefig(png_file_path)
    
    return png_file_path

#custom_labels = ['モータON', 'モータ 100%', '', '加速', '走行', 'ジャンプ', 'ブレーキON待ち', 'ブレーキON', '回転抑制待ち', '回転抑制中', 'モータフリー']

def plot_selected_columns(df_filtered, file_name):
    # 新たなデータをdf_filteredに追加
    df_filtered['GrvAvg'] = (df_filtered['GrvX'] + df_filtered['GrvY'] + df_filtered['GrvZ']) / 3

    fig, axes = plt.subplots(2, 1, figsize=(10, 12))
    axes = axes.flatten()

    # 'GrvAvg'をsecondaryに追加
    selected_sets = [
        {'primary': [('FLOW2', 'orange'), ('MOT2', 'g')], 'secondary': [('GrvX', 'b'), ('GrvAvg', 'purple')]},
        {'primary': [('FLOW2', 'orange'), ('MOT2', 'g')], 'secondary': [('Pitch', 'b')]}
    ]

    for i, selected in enumerate(selected_sets):
        ax1 = axes[i]
        ax2 = ax1.twinx()

        ax1.grid(True, which='major', axis='both')

        ax1.minorticks_on()
        ax1.xaxis.grid(which='minor', linestyle='-.', linewidth='0.5', color='grey')

        for col, col_color in selected['primary']:
            if col in df_filtered.columns:
                ax1.plot(df_filtered['Time'], df_filtered[col], label=f'{col} (left axis)', color=col_color)

        for col, col_color in selected['secondary']:
            if col in df_filtered.columns:
                ax2.plot(df_filtered['Time'], df_filtered[col], label=f'{col} (right axis)', color=col_color, linestyle='--')

        ax1.set_xlabel('Time(us)')

        custom_labels = ['モータON', 'モータ 100%', '', '加速', '走行', 'ジャンプ', 'ブレーキON待ち', 'ブレーキON', '回転抑制待ち', '回転抑制中', 'モータフリー']

        ax1.set_yticks(range(0, 11))
        ax1.set_yticklabels(custom_labels)

        lines, labels = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax2.legend(lines + lines2, labels + labels2, loc='upper left')

    plt.tight_layout()

    png_file_name = os.path.splitext(file_name)[0] + '_selected_columns.png'
    png_file_path = f'{png_file_name}'
    plt.savefig(png_file_path)

    return png_file_path






def main():
    file_path = './log/20231010204340_18th.csv'
    file_name = os.path.basename(file_path)
    with open(file_path, 'rb') as f:
        file_data = f.read()

    # カラムヘッダーを追加します
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




    df = filter_imu_rows(df)
    df = convert_columns_to_numeric(df)
    file_name_png = plot_and_save(df, file_name)
    df = df[df['FLOW2'] >= 5]
    df = df[df['FLOW2'] <= 10]
    selected_columns_png = plot_selected_columns(df, file_name)

if __name__ == "__main__":
    main()
