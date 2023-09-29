import base64

# CSVファイルをバイナリモードで読み込む
with open("sin_wave.csv", "rb") as f:
    file_data = f.read()

# Base64エンコード
file_data_b64 = base64.b64encode(file_data).decode("utf-8")

# エンコードされたデータを出力
print(file_data_b64)
