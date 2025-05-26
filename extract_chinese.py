#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys

# 双引号内容的正则表达式
# 匹配text = "内容"格式的文本
TEXT_PATTERN = re.compile(r'text\s*=\s*"(.*?)"', re.DOTALL)
# 匹配add_toast("")格式的文本
TOAST_PATTERN = re.compile(r'add_toast\s*\(\s*"(.*?)"\s*\)', re.DOTALL)
# 匹配所有双引号内的文本(用于JSON文件)
JSON_TEXT_PATTERN = re.compile(r'"(.*?)"', re.DOTALL)

# 要忽略的文件和目录
IGNORE_DIRS = ['.git', '.import', 'addons', 'build', 'release']  
# 只处理这些扩展名的文件
INCLUDE_EXTENSIONS = ['.gd', '.tscn', '.json']

# 输出文件名
OUTPUT_FILE = 'game_texts.txt'

# 需要手动额外插入的数据
MANUAL_INSERT_DATA = [
    "钢铁之拳",
	"雷鸣战士",
	"盾墙守护者",
	"破甲勇士",
	"铁血骑士",
	"战锤英雄",
	"钢铁意志",
	# 法师职业
	"月光法师",
	"火焰术士",
	"冰霜咏唱者",
	"暗影法师",
	"风暴召唤师",
	"星辰占卜师",
	"奥术导师",
	# 盗贼职业
	"暗影游侠",
	"迅捷猎手",
	"暗夜潜行者",
	"迅影盗贼",
	"无声隐士",
	"机敏侠客"
]

# 注释正则表达式
GD_COMMENT_PATTERN = re.compile(r'#.*?$', re.MULTILINE)  # GDScript单行注释
TSCN_COMMENT_PATTERN = re.compile(r';.*?$', re.MULTILINE)  # TSCN文件注释
JSON_COMMENT_PATTERN = re.compile(r'(//.*?$|/\*.*?\*/)', re.MULTILINE | re.DOTALL)  # JSON非标准注释

def should_process_file(file_path):
    """判断是否应该处理该文件"""
    # 检查文件扩展名
    _, ext = os.path.splitext(file_path)
    # 只处理指定扩展名的文件
    if ext.lower() not in INCLUDE_EXTENSIONS:
        return False
    
    return True

def remove_comments(content, file_ext):
    """根据文件类型移除注释"""
    if file_ext == '.gd':
        # 移除GDScript注释
        return GD_COMMENT_PATTERN.sub('', content)
    elif file_ext == '.tscn':
        # 移除TSCN文件注释
        return TSCN_COMMENT_PATTERN.sub('', content)
    elif file_ext == '.json':
        # 移除JSON文件可能的非标准注释
        return JSON_COMMENT_PATTERN.sub('', content)
    return content

def extract_quoted_text_from_file(file_path):
    """从文件中提取双引号内的文本"""
    quoted_texts = set()
    _, file_ext = os.path.splitext(file_path)
    is_json = file_ext.lower() == '.json'
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
            # 移除注释
            content = remove_comments(content, file_ext.lower())
            
            # 根据文件类型选择不同的处理方式
            if is_json:
                # JSON文件：提取所有双引号内的内容
                for match in JSON_TEXT_PATTERN.finditer(content):
                    quoted_text = match.group(1)  # 组1是引号内的内容
                    if quoted_text.strip():  # 忽略空字符串
                        quoted_texts.add(quoted_text)
            else:
                # 其他文件：只提取特定格式的文本
                # 查找所有text = "内容"格式的文本
                for match in TEXT_PATTERN.finditer(content):
                    quoted_text = match.group(1)  # 组1是引号内的内容
                    if quoted_text.strip():  # 忽略空字符串
                        quoted_texts.add(quoted_text)
                
                # 查找所有add_toast("")格式的文本
                for match in TOAST_PATTERN.finditer(content):
                    quoted_text = match.group(1)  # 组1是引号内的内容
                    if quoted_text.strip():  # 忽略空字符串
                        quoted_texts.add(quoted_text)
    except Exception as e:
        print(f"无法读取文件 {file_path}: {e}")
    
    return quoted_texts

def scan_directory(directory):
    """扫描目录下的所有文件，提取双引号内的文本"""
    all_quoted_texts = set()
    file_count = 0
    text_file_count = 0
    
    for root, dirs, files in os.walk(directory):
        # 忽略指定目录
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        for file in files:
            file_path = os.path.join(root, file)
            if should_process_file(file_path):
                file_count += 1
                quoted_texts = extract_quoted_text_from_file(file_path)
                if quoted_texts:
                    text_file_count += 1
                    print(f"发现文本内容在: {file_path}")
                    all_quoted_texts.update(quoted_texts)
    
    return all_quoted_texts, file_count, text_file_count

def save_to_file(texts, output_file):
    """将提取的文本保存到文件"""
    # 将手动插入的数据添加到集合中
    for item in MANUAL_INSERT_DATA:
        # 跳过注释行
        if not item.strip().startswith('#'):
            texts.add(item.strip())
    
    # 按文本排序
    sorted_texts = sorted(list(texts))
    
    with open(output_file, 'w', encoding='utf-8') as f:
        # 每行写入一个文本
        for text in sorted_texts:
            f.write(f"{text}\n")

def main():
    # 获取当前目录或命令行参数指定的目录
    directory = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    output_file = os.path.join(directory, OUTPUT_FILE)
    
    print(f"开始扫描目录: {directory}")
    print(f"只检查扩展名为: {', '.join(INCLUDE_EXTENSIONS)} 的文件")
    print(f"注意: 代码中的注释内容将被忽略")
    print(f"正在提取双引号内的所有文本...")
    
    quoted_texts, file_count, text_file_count = scan_directory(directory)
    
    if quoted_texts:
        manual_data_count = sum(1 for item in MANUAL_INSERT_DATA if not item.strip().startswith('#'))
        save_to_file(quoted_texts, output_file)
        print(f"\n扫描完成:")
        print(f"已处理 {file_count} 个文件")
        print(f"发现包含文本的文件 {text_file_count} 个")
        print(f"共提取出 {len(quoted_texts)} 个不同的文本字符串")
        print(f"额外手动添加了 {manual_data_count} 个文本字符串")
        print(f"结果已保存到: {output_file}")
    else:
        manual_data_count = sum(1 for item in MANUAL_INSERT_DATA if not item.strip().startswith('#'))
        if manual_data_count > 0:
            save_to_file(set(), output_file)
            print(f"虽然未从文件中提取到文本，但已添加 {manual_data_count} 个手动插入的文本")
            print(f"结果已保存到: {output_file}")
        else:
            print("未发现任何文本")

if __name__ == "__main__":
    main()