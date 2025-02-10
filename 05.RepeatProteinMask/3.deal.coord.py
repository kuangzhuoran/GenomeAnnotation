import os
import argparse

# 创建参数解析器
parser = argparse.ArgumentParser(description="Update .annot file coordinates, remove part of filename, and merge them.")
parser.add_argument("input_dir", help="Directory containing the .annot files (e.g., chr1.fa.split)")
parser.add_argument("split_size", type=int, help="Size of each split (e.g., 4000)")
parser.add_argument("output_file", help="Path to the final merged .annot file (e.g., merged.annot)")

# 解析命令行参数
args = parser.parse_args()

# 获取输入文件夹中的所有.annot文件
annot_files = sorted([f for f in os.listdir(args.input_dir) if f.endswith(".fa.annot")])

# 用于存储合并后的内容
merged_lines = []
header_saved = False  # 标记是否已保存表头

# 遍历每个 .annot 文件并更新坐标
for annot_file in annot_files:
    input_file = os.path.join(args.input_dir, annot_file)
    
    # 检查文件是否为空
    if os.path.getsize(input_file) == 0:
        print(f"Skipping empty file: {input_file}")
        continue

    # 获取当前子序列的索引（从文件名中提取）
    part_index = int(annot_file.split('_part_')[1].split('.fa.annot')[0])
    
    # 计算偏移量（每个子序列的起始位置）
    offset = part_index * args.split_size
    
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    updated_lines = []
    for i, line in enumerate(lines):
        if i == 0:  # 处理表头
            if not header_saved:
                merged_lines.append(line.strip())  # 只保留第一个文件的表头
                header_saved = True
            continue  # 跳过其他文件的表头
        
        # 拆分每行的数据
        columns = line.strip().split()
        
        # 更新 Begin 和 End 坐标
        if len(columns) > 5:
            begin = int(columns[4])
            end = int(columns[5])
            
            # 更新坐标
            columns[4] = str(begin + offset)
            columns[5] = str(end + offset)
            
            # 更新文件名为染色体名（去除 _part_X 部分）
            columns[3] = annot_file.split('_part_')[0]  # 取文件名的前半部分作为染色体名
            
            updated_lines.append("\t".join(columns))
    
    # 将更新后的行添加到合并内容
    merged_lines.extend(updated_lines)
    print(f"Updated {input_file}")

# 将所有更新后的内容写入输出文件
with open(args.output_file, 'w') as f:
    f.write("\n".join(merged_lines) + "\n")

print(f"Finished updating and merging all .annot files into {args.output_file}")

