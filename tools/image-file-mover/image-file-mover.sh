#!/bin/bash

# filepath: c:\workspace\train-editor\tools\image-file-mover\image-file-mover.sh

# 引数チェック
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <absolute_path_to_parent_directory>"
    exit 1
fi

# 親フォルダの定義
PARENT_DIR="$1"
SOURCE_DIR="$PARENT_DIR/only_official"
DEST_ALL="$PARENT_DIR/only_official_all"
DEST_DEFAULT="$PARENT_DIR/only_official_default"
DEST_REAL="$PARENT_DIR/only_official_real"

# SOURCE_DIR の存在確認
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: $SOURCE_DIR does not exist."
    exit 1
fi

# 必要なフォルダを削除して再作成
rm -rf "$DEST_ALL" "$DEST_DEFAULT" "$DEST_REAL"
mkdir -p "$DEST_ALL" "$DEST_DEFAULT" "$DEST_REAL"

# フォルダを走査
for folder in "$SOURCE_DIR"/*; do
    if [ -d "$folder" ]; then
        folder_name=$(basename "$folder")

        # 先頭が数値で始まらないフォルダはスキップ
        if ! [[ "$folder_name" =~ ^[0-9] ]]; then
            echo "Skipping folder: $folder_name (does not start with a number)"
            continue
        fi

        # 現実側フォルダ (数値_real_*)
        if [[ "$folder_name" == *_real_* ]]; then
            mkdir -p "$DEST_REAL/$folder_name"
            mkdir -p "$DEST_ALL/$folder_name"
            cp "$folder"/*.{png,jpeg,webp,txt} "$DEST_REAL/$folder_name" 2>/dev/null
            cp "$folder"/*.{png,jpeg,webp,txt} "$DEST_ALL/$folder_name" 2>/dev/null

        # アストルム側フォルダ (数値_* だが *_real_* を除く)
        elif [[ "$folder_name" == *_* && "$folder_name" != *_real_* ]]; then
            mkdir -p "$DEST_DEFAULT/$folder_name"
            mkdir -p "$DEST_ALL/$folder_name"
            cp "$folder"/*.{png,jpeg,webp,txt} "$DEST_DEFAULT/$folder_name" 2>/dev/null
            cp "$folder"/*.{png,jpeg,webp,txt} "$DEST_ALL/$folder_name" 2>/dev/null
        fi
    fi
done

# テキストファイルと同名の画像ファイルのみを残す
for dest in "$DEST_ALL" "$DEST_DEFAULT" "$DEST_REAL"; do
    for txt_file in $(find "$dest" -type f -name "*.txt"); do
        base_name=$(basename "$txt_file" .txt)
        dir_name=$(dirname "$txt_file")
        for img_file in "$dir_name"/*.{png,jpeg,webp}; do
            if [[ $(basename "$img_file") != "$base_name".* ]]; then
                rm -f "$img_file"
            fi
        done
    done
done