#!/usr/bin/env perl
use strict;
use warnings;

# ---------------------------------------------------------
# 功能：将输入的多序列FASTA按照“>ID”分割，并输出到指定目录
# 用法: perl split_fasta.pl <input_fasta> <output_dir>
# ---------------------------------------------------------

# 获取命令行参数
my ($fasta_file, $out_dir) = @ARGV;
if (not defined $fasta_file or not defined $out_dir) {
    die "用法: perl $0 <input_fasta> <output_dir>\n";
}

# 如果输出目录不存在，则尝试创建
unless (-d $out_dir) {
    mkdir $out_dir or die "无法创建输出目录 $out_dir: $!";
}

# 打开输入FASTA
open my $IN, "<", $fasta_file or die "无法打开输入文件 $fasta_file: $!";

my $out_fh;   # 指向当前输出文件的句柄
my $seq_id;   # 当前序列ID（从>行提取）

while (<$IN>) {
    chomp;
    # 如果是序列ID行（以>开头）
    if (/^>(\S+)/) {
        $seq_id = $1;  # 获取染色体/contig ID（只取 > 后的第一个非空字符串）
        
        # 如果已经有打开的输出文件，先关闭
        if (defined $out_fh) {
            close $out_fh;
        }
        
        # 打开一个新的输出文件，以 ID.fa 命名
        my $out_file = "$out_dir/$seq_id.fa";
        open($out_fh, ">", $out_file) or die "无法写入 $out_file: $!";
        
        # 在新文件里写入 ">" 行
        print $out_fh ">$seq_id\n";
    }
    else {
        # 如果是序列行，则写入当前输出文件
        print $out_fh $_, "\n" if defined $out_fh;
    }
}

close $IN;
close $out_fh if defined $out_fh;

exit 0;
