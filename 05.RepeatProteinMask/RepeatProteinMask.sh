#按染色体切割基因组，多染色体并行加速
perl split_fasta.pl merlin.fa merlin.split


for i in merlin.split/*
do
echo "RepeatProteinMask -noLowSimple -pvalue 1e-04 $i" >> merlin.split.run.sh
done


sh merlin.split.run.sh


cat merlin.split/*annot > merlin.repeatproteinmasker.annot
perl ConvertRepeatMasker2gff.pl merlin.repeatproteinmasker.annot TP.gff TP
#生成的merlin.TP.gff就是后续用到的注释文件,同其他重复序列注释合并然后去冗余
#做到这就够了




#注，有些时候部分染色体实在是太长了，运行太慢了
#这个时候我们可以把染色体人为的切割为比如1Mb的子序列，再对这个子序列运行程序
#以chr1为例
python 1.split.fa.py  chr1.fa  1000000  ./chr1.fa.split  #1000000即把序列按照1Mb切割为子序列   ./chr1.fa.split是输出文件夹
#假设chr1.fa在当前路径底下，会生成chr1.fa.split，子序列都存放其中

python 2.get.reppro.sh.py  /path/to/RepeatProteinMask  ./chr1.fa.split  chr1.fa.sh
ParaFly -c chr1.fa.sh -CPU 30

python 3.deal.coord.py ./chr1.fa.split  1000000  chr1.fa.merge.annot  #chr1.fa.merge.annot即最后的结果
