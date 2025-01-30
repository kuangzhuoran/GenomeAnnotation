import os
import argparse

# 创建参数解析器
parser = argparse.ArgumentParser(description="Batch generate RepeatProteinMask command lines for split genome sequences.")
parser.add_argument("repeat_masker_path", help="Path to the RepeatProteinMask executable (e.g., /path/to/RepeatProteinMask)")
parser.add_argument("input_dir", help="Directory containing the split genome sequence files (e.g., chr1.fa.split)")
parser.add_argument("output_file", help="Output file to save the generated commands (e.g., commands.txt)")

# 解析传入的命令行参数
args = parser.parse_args()

# 获取输入文件夹中的所有FASTA文件
genome_files = [f for f in os.listdir(args.input_dir) if f.endswith(".fa")]

# 打开输出文件用于写入命令行
with open(args.output_file, 'w') as output:
    for genome_file in genome_files:
        input_file = os.path.join(args.input_dir, genome_file)
        
        # 构建 RepeatProteinMask 命令行
        command = f"{args.repeat_masker_path} -noLowSimple -pvalue 1e-04 {input_file}\n"
        
        # 写入命令到输出文件
        output.write(command)

print(f"Generated command lines have been saved to {args.output_file}")

