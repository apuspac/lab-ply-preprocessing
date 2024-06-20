# plyファイルのエラー点を除去する

LiDARなどで計測した点群のエラー点を除去するためのプログラム

中心から半径3.0m以内の点を残す場合は、
```
./preprocess.sh --input "ply_file.ply"  --radius 3.0
```

property_numがいらないよう改善
NOTE: windowsで動かすと 改行が悪さしてるぽいので、以下で改行コードを置換する
```bash
sed -i 's/\r//' *.sh
```


## option
- -h, --help  
- -i, --input [ARG]  
input filenameを指定。
- -o, --output [ARG]  
output filenameを指定。デフォルトはoutput.ply
- -p, --property_num [ARG]  
plyファイルのオプションの数を指定。
plyファイルのheaderにあるpropertyの個数を指定して判別する用だった。  
>> これは自動で数えるように変更。  
>> というかxyzはたいてい最初なので、この処理はいらなかった。
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
 原点からのxy半径を指定する。  
 各点のユークリッド距離を計算して、設定した値以上の点を除去する。
 x,yの値からしか距離計算をしておらず、z(高さ)は考慮していない。

- -re, --rectangle [ARG1] [ARG2] [ARG3] [ARG4]  
原点から矩形範囲を指定する。画像参照  
こちらも高さは計算していない。
arg1 = xのプラス範囲  
arg2 = xのマイナス範囲  
arg3 = yのプラス範囲  
arg4 = yのマイナス範囲  

![](img/rec.svg)
