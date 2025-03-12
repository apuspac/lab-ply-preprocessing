# plyファイル 前処理

LiDAR などで計測した点群のエラー点, outlierを除去するためのプログラム

中心から半径 3.0m 以内の点を残す場合は、

```
./preprocess.sh --input "ply_file.ply"  --radius 3.0
```

NOTE: windows で動かすと 改行が悪さしてるぽいので、以下で改行コードを置換する

```bash
sed -i 's/\r//' *.sh
```

## option

- -h, --help
- -i, --input [ARG]  
  input filename を指定。
- -o, --output [ARG]  
  output filename を指定。デフォルトは output.ply
- -p, --property_num [ARG]  
  ply ファイルのオプションの数を指定。
  ply ファイルの header にある property の個数を指定して判別する用だった。
  > これは自動で数えるように変更。  
  > というか xyz はたいてい最初なので、この処理はいらなかった。

```
ply
format ascii 1.0
comment ViewPLUS PointType : struct vp::PointXYZITRGBA
element vertex 381571
property float x
property float y
property float z
property float intensity
property double time_stamp
property uchar blue
property uchar green
property uchar red
property uchar alpha
end_header
```

- -ra, --radius [ARG]  
  原点からの xy 半径を指定する。  
  各点のユークリッド距離を計算して、設定した値以上の点を除去する。
  x,y の値からしか距離計算をしておらず、z(高さ)は考慮していない。

- -re, --rectangle [ARG1] [ARG2] [ARG3] [ARG4]  
  原点から矩形範囲を指定する。画像参照  
  こちらも高さは計算していない。
  arg1 = x のプラス範囲  
  arg2 = x のマイナス範囲  
  arg3 = y のプラス範囲  
  arg4 = y のマイナス範囲


<!-- 
![](img/rec.svg)
-->

