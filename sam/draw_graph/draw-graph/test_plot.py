import pandas as pd
import matplotlib.pyplot as plt

df = pd.DataFrame({
            'x': [1, 2, 3, 4, 5],
            'y': [1, 4, 9, 16, 25]
        })

# データをプロット
fig = plt.figure()
plt.figure(figsize=(10, 6))
plt.plot(df['x'], df['y'], marker='o')
plt.title('Sample Plot')
plt.xlabel('X-axis')
plt.ylabel('Y-axis')
plt.grid(True)

print(f"finish plot")

# 凡例を表示します
plt.legend()

# グラフを表示します
plt.show()
