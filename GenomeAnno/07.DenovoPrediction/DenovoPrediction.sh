#安装AUGUSTUS
#安装genscan

#根据前面得到的gff,对基因组文件进行软屏蔽
bedtools maskfasta -fi merlin.fa -bed repeat.merge.bed -fo merlin.softmasked.fa -soft

perl split_fasta.pl merlin.softmasked.fa merlin.split
#将染色体按照染色体切割

#首先使用chicken的模型
mkdir merlin.chicken.augustus
for i in `ls merlin.split`
do
echo "./augustus --softmasking=1 --species=chicken merlin.split/$i --UTR=off | perl ConvertFormat_augustus.pl - merlin.augustus/$i.gff" >> augustus.sh
done
sh augustus.sh
#ParaFly -c augustus.sh -CPU 20 -failed_cmds augustus.failed
#可以再运行human的模型

cat merlin.augustus/chr1.gff merlin.augustus/chr2.gff... | sed 's/augustus/chicken/g' > merlin.chicken.denovo.gff
#最后用于EVM的是merlin.chicken.denovo.gff
#注意，最后我们修改了gff文件的第二列，以便后面区分不同的denovo预测的gff


#其次基于BUSCO自己训练模型
#wget https://busco-data.ezlab.org/v5/data/lineages/aves_odb10.2024-01-08.tar.gz
#自行选择亲缘关系更近的库
#tar -zxvf aves_odb10.2024-01-08.tar.gz
#得到文件夹aves_odb10
#busco -m genome -i merlin.fa -c 15 --long  --augustus --offline -f -l /path/to/aves_odb10
#会生成一个文件夹叫：BUSCO_merlin.fa
#将其中的run_aves_odb10/augustus_output/retraining_parameters,这个文件夹copy到Augustus的安装目录中
#cp -r run_aves_odb10/augustus_output/retraining_parameters /path/to/augustus/$i
#然后运行：
mkdir merlin.BUSCO.augustus
for i in `ls merlin.split`
do
echo "./augustus --softmasking=1 --species=BUSCO_merlin.fa merlin.split/$i --UTR=off | perl ConvertFormat_augustus.pl - merlin.BUSCO.augustus/$i.gff" >> augustus.busco.sh
done
sh augustus.busco.sh
#ParaFly -c augustus.busco.sh -CPU 20 -failed_cmds augustus.failed
#可以再运行human的模型



#这里，我们再多运行一个软件Helixer
#是否软屏蔽对这个软件的影响不大
#https://github.com/weberlab-hhu/Helixer
#source ~/miniconda3/bin/activate && conda activate Helixer
#export LD_LIBRARY_PATH=~/miniconda3/envs/Helixer/lib:$LD_LIBRARY_PATH
Helixer.py --lineage vertebrate --fasta-path merlin.fa  \
 --no-multiproces --temporary-dir /bak03/kuangzhuoran/tmp --species merlin.hap1 --gff-output-path merlin.helixer.gff3 --temporary-dir
 #1.2G左右的基因组大小，耗时32小时
 
 #最后用于EVM的是merlin.helixer.gff3
 