import cv2
import numpy as np

# ビデオファイルの読み込み
cap = cv2.VideoCapture('trim.mp4')

# 背景差分アルゴリズムの設定
bg_subtractor = cv2.createBackgroundSubtractorMOG2()

# モルフォロジー変換用のカーネル
kernel = np.ones((5, 5), np.uint8)

# 最初のフレームを保存しておく変数
first_frame = None

# フレームスキップの設定（5フレームごとに1フレーム取得）
frame_skip = 3
counter = 0

while True:
    ret, frame = cap.read()
    counter += 1

    # フレームが終わったらループから抜ける
    if not ret:
        break

    if counter % frame_skip != 0:
        continue

    # 背景差分を適用して二値画像を作成
    fg_mask = bg_subtractor.apply(frame)

    # モルフォロジー変換（オープニング）でノイズ除去
    fg_mask = cv2.morphologyEx(fg_mask, cv2.MORPH_OPEN, kernel)

    # モルフォロジー変換（ダイレーション）で広がりを持たせる
    fg_mask = cv2.dilate(fg_mask, kernel, iterations=2)

    # 二値画像で閾値より小さい部分を強制的に0にする
    _, fg_mask = cv2.threshold(fg_mask, 127, 255, cv2.THRESH_BINARY)

    # カラー画像にマスクを適用
    fg_color = cv2.bitwise_and(frame, frame, mask=fg_mask)

    # 動いていない部分を黒にする
    if 0:
        frame[fg_mask == 0] = 0
    

    # 最初のフレームを保存
    if first_frame is None:
        first_frame = frame.copy()

    # 動いている部分をオーバーラップ
    np.maximum(first_frame, fg_color, out=first_frame)

# オーバーラップされた画像を保存
cv2.imwrite('overlap_black_background_reduced_frame_rate.png', first_frame)

# キャプチャを解放
cap.release()

print('Done!')
