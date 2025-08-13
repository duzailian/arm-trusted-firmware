#!/usr/bin/python3
import os
import json
import argparse

def main():
    parser = argparse.ArgumentParser(description='Retain .c/.S files specified in JSON and delete others.')
    parser.add_argument('json_file', help='Path to the JSON file')
    parser.add_argument('-y', '--yes', action='store_true', help='Automatically confirm deletion')
    args = parser.parse_args()

    # 读取JSON文件并提取所有file字段的值（只保留.c/.S文件）
    keep_files = set()
    try:
        with open(args.json_file, 'r') as f:
            data = json.load(f)
            for entry in data:
                file_path = entry.get('file', '')
                if file_path.lower().endswith(('.c', '.s')):
                    keep_files.add(os.path.abspath(file_path))
    except Exception as e:
        print(f"Error reading JSON file: {e}")
        return

    # 遍历当前目录及所有子目录
    delete_list = []
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.lower().endswith(('.c', '.s')):
                full_path = os.path.abspath(os.path.join(root, file))
                # 检查文件是否在保留列表中
                if full_path not in keep_files:
                    delete_list.append(full_path)

    # 如果没有需要删除的文件则退出
    if not delete_list:
        print("No files to delete.")
        return

    # 显示删除列表并确认
    print(f"Found {len(delete_list)} files to delete:")
    for i, f in enumerate(delete_list[:5]):
        print(f"  [{i+1}] {f}")
    if len(delete_list) > 5:
        print(f"  ... and {len(delete_list)-5} more")

    if not args.yes:
        response = input("\nProceed with deletion? [y/N] ").strip().lower()
        if response != 'y':
            print("Deletion canceled.")
            return

    # 执行删除操作
    deleted_count = 0
    for file_path in delete_list:
        try:
            os.remove(file_path)
            deleted_count += 1
        except Exception as e:
            print(f"Error deleting {file_path}: {e}")

    print(f"Successfully deleted {deleted_count}/{len(delete_list)} files")

if __name__ == "__main__":
    main()
