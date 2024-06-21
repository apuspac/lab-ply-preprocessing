#!/bin/bash

# sed -i 's/\r//' *.sh

<< COMMENTOUT
シェルスクリプトについて
https://qiita.com/zayarwinttun/items/0dae4cb66d8f4bd2a337

オプション処理について
https://qiita.com/b4b4r07/items/dcd6be0bb9c9185475bb#%E3%81%84%E3%81%A3%E3%81%9D%E8%87%AA%E5%89%8D%E3%81%A7%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A1%E3%82%83%E3%81%86

<<<<<<< HEAD
print $1, "", $2, "", $3

=======
>>>>>>> c4b3ae4 (first)

COMMENTOUT


PROGNAME=$(basename $0)
VERSION="1.0"

# 使い方
usage() {
    echo "$PROGNAME"
    echo "This script preprocess the ply_file. it removes large distance points in a point cloud"
    echo
    echo "Usage: $PROGNAME [OPTION]..."
    echo "Options:"
    echo "  -h, --help          print help and exit"
    echo "  -i, --input [ARG]    input filename"
    echo "  -o, --output [ARG]     output filename. default 'output.ply'"
    echo "  -p, --property_num [ARG] plyfile property num. default 4"
    echo "  -ra, --radius [ARG] Circle radius to remove points (float)"
    echo "  -re, --rectangle [ARG1] [ARG2] [ARG3] [ARG4] length of rectangle to remove points (float), plus_x, minus_x, plus_y, minus_y, from the center of the rectangle "
    exit 1
}

# default値
output_file="output.ply"
radius_range=3.0
method_FLAG=1
rect_negative_x=1.5
rect_positive_x=1.5
rect_negative_y=1.5
rect_positive_y=1.5
property_num=9


# オプション処理
for OPT in "$@"
do
    case $OPT in
        -h | --help)
            usage
            exit 1
            ;;
        --version)
            echo $VERSION
            exit 1
            ;;
        -i | --input)
        # 第二引数が emptyもしくは 次のオプションになっていないか
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument about input ply_filename -- $1" 1>&2
                exit 1
            fi
            input_file=$2
            shift 2
            ;;
        -o | --output)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument about output ply_filename -- $1" 1>&2
                exit 1
            fi
            output_file=$2
            shift 2
            ;;
        # 点を除去しない円の半径。この距離より遠ければ消す。
        -ra | --radius)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            radius_range=$2
            shift 2
            ;;
        # 矩形の許可範囲
        -re | --rectangle)
            # 第5引数まで値が入っていないとエラー
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]] || [[ -z "$3" ]] || [[ "$3" =~ ^-+ ]] || [[ -z "$4" ]] || [[ "$4" =~ ^-+ ]] || [[ -z "$5" ]] || [[ "$5" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            rect_positive_x=$2
            rect_negative_x=$3
            rect_positive_y=$4
            rect_negative_y=$5
            method_FLAG=0
            shift 5
            ;;
        -p | --property_num)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            property_num=$2
            shift 2
            ;;

        -*)
            echo "$PROGNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ ! -z "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                #param=( ${param[@]} "$1" )
                param+=( "$1" )
                shift 1
            fi
            ;;
    esac
done

# すべての変数がそろっているかどうか 確認して そろってなかったら 終了
if [[ -z ${input_file} ]]; then
    echo "$PROGNAME: requires input ply file" 1>&2
    exit 1
fi

echo "
inputfile ${input_file}
outputfile ${output_file}"
if [ $method_FLAG -eq 1 ]; then
    echo "radius ${radius_range}"
else
    echo "rectangle ${rect_negative_x} ${rect_positive_x} ${rect_negative_y} ${rect_positive_y}"
fi

# ここから下まで awk
awk -v property_number=${property_num} -v accept_range=${radius_range}  -v rectangle_nx=${rect_negative_x} -v rectangle_px=${rect_positive_x} -v rectangle_ny=${rect_negative_y} -v rectangle_py=${rect_positive_y} -v method_flag=${method_FLAG} '

function abs(x)
{
   return (x < 0) ? -x : x
}

function pow(x)
{
    return abs(x) * abs(x)
}

# 対象の点が円より小さければ true
function is_fit_in_range_Euclidean(x, y)
{
    if(sqrt(pow(x) + pow(y)) < accept_range){
        return "true"
    }
}

# 対象の点が矩形より小さければ
function is_fit_in_range_Rectangle(x, y)
{
    if((x > (rectangle_nx)*(-1)) && (x < rectangle_px)){
        if((y > (rectangle_ny)*(-1)) && (y < rectangle_py)){
            return "true"
        }
    }
}

#
function is_fit_in_range(x, y)
{
    px = x
    py = y
    result = "false"

    if(method_flag == 1){
        result = is_fit_in_range_Euclidean(px, py)
    }else{
        result = is_fit_in_range_Rectangle(px, py)
    }
    return result
}

BEGIN{
    elements = 0
    elements_line = 0
    property_num_count = 0
}

{
    if ($1 + 0 == $1) {
        # 数値の場合
        if(NF == property_number){
            if(is_fit_in_range($1, $2)){
                print $1, $2, $3
                elements++
            }else{
                next
            }
        }
    } else {
        # 文字列の場合
        # element vertex の行番号を保存
        if($1 == "element" && $2 == "vertex"){
            elements_line = NR
        }
        else{
            if($1 == "end_header"){
                print $0
                property_number = property_num_count
            }
            else{
                if($1 == "property"){
                    property_num_count++
                    if($2 == "float"){
                        if($3 == "x" || $3 == "y" || $3 == "z"){
                            print $0
                        }
                        else{
                            next
                        }
                    }
                }
                else{
                    print $0
                }
            }
        }
    }
}

END{
    # element vertexの値だけ外に保持しておく。
    print elements_line,elements > "elements_vertex_tmp"
}
' $input_file > $output_file

# 標準入力からelements_vertex_tmpをreadで受け取って変数に代入
read elements_line elements_vertex <<< $(cat "elements_vertex_tmp" | awk '{print $1,$2}')


echo "element vertex $elements_vertex"

# elements vertex があった場所に新しいものを挿入
# 3i "text" で3行目 をtextで挿入
sed -i -e ""$elements_line"i  element vertex "$elements_vertex"" $output_file

rm elements_vertex_tmp

# sed 's/0\.000000//g' $output_file > $output_file
# sed 's/0\.000000//g' $output_file > temp_file && mv temp_file $output_file


exit $?


# awkからシェルスクリプトへ変数として渡したいので、setコマンドを使ってみる

# BEGIN{
#     property_number = 9
#     accept_range = 3.0
#     file_name = "500mm-2nd-600.ply"


#     # check vertex number in accept_range
#     elements = 0

#     while((getline < file_name) > 0){
#         if(NF == property_number){
#             if(is_fit_in_range($1, $2)){
#                 elements++
#             }
#         }
#     }close(file_name)

# }

# {


#     if(NF == property_number){
#         if(is_fit_in_range($1, $2)){
#             print $0
#         }else{
#             next
#         }
#     }else{
#         # change vertex elements
#         if($1 == "element" && $2 == "vertex"){
#             print $1, $2, elements
#         }
#         else{
#             print $0
#         }
#     }
# }


'
