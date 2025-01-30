import os
import argparse

# 创建参数解析器
parser = argparse.ArgumentParser(description="Split a FASTA file into smaller sequences and update coordinates.")
parser.add_argument("input_file", help="Path to the input FASTA file (e.g., chr1.fa)")
parser.add_argument("split_size", type=int, help="Size of each split (e.g., 4000)")
parser.add_argument("output_dir", help="Directory to store the split files (e.g., ./split_files)")

# 解析命令行参数
args = parser.parse_args()

# 创建输出文件夹，如果不存在的话
if not os.path.exists(args.output_dir):
    os.makedirs(args.output_dir)

# 读取输入FASTA文件
with open(args.input_file, 'r') as f:
    lines = f.readlines()

# 提取FASTA序列，跳过以'>'开头的描述行
seq = ''.join(line.strip() for line in lines if not line.startswith('>'))

# 计算总的序列长度
seq_len = len(seq)

# 打印总长度
print(f"Total sequence length: {seq_len} bases")

# 根据split_size切割FASTA序列
num_parts = (seq_len + args.split_size - 1) // args.split_size  # 向上取整

for i in range(num_parts):
    # 计算每个子序列的起始和结束位置
    start = i * args.split_size
    end = min((i + 1) * args.split_size, seq_len)
    
    # 提取子序列
    subseq = seq[start:end]
    
    # 生成输出文件名
    part_filename = os.path.join(args.output_dir, f"{os.path.basename(args.input_file).replace('.fa', '')}_part_{i}.fa")
    
    # 写入子序列到文件
    with open(part_filename, 'w') as part_file:
        part_file.write(f">{os.path.basename(part_filename)}\n")
        part_file.write(subseq + "\n")
    
    print(f"Created {part_filename}")

print(f"Finished splitting the sequence into {num_parts} parts.")

