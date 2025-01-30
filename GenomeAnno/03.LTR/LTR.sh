#安装https://github.com/oushujun/LTR_retriever
#安装https://github.com/oushujun/LTR_FINDER_parallel
#安装https://github.com/genometools/genometools

#安装parallel;
#conda install -c conda-forge parallel
#parallel不是必须的,SplitRunLTRharvest.pl中是用这个来并行命令行了
#自行修改SplitRunLTRharvest.pl也可以


vim LTR.InsertTime.pl
vim SplitRunLTRharvest.pl
#将这几个脚本中相应软件的路径以及脚本替换掉


#安装BioPerl
#conda install -c bioconda perl-bioperl


#Let's begin
perl LTR.InsertTime.pl merlin.fa merlin LTR_retrieverno 15
#会生成一个merlin的文件夹,里面有个脚本叫做merlin.retriever.sh


sh merlin.retriever.sh


cat ./03.LTR_retriever/merlin.genome.fna.LTRlib.redundant.fa  RepeatMasker.lib  RM_16144.SatDec211808382024/consensi.fa.classified  >  fix.lib
#./03.LTR_retriever/merlin.hap2.genome.fna.LTRlib.redundant.fa即这里的输出结果
#RepeatMasker.lib是Dfam+RepBase，但是RepeatMasker自带的RepBase的版本已经很老了
#安装RepeatMasker的时候，需要配置数据库，详情参阅https://github.com/Dfam-consortium/RepeatMasker/blob/master/INSTALL
#RM_16144.SatDec211808382024/consensi.fa.classified是我们用RepeatModeler-2.0.3自己建的库
#这里的RepeatMasker.lib，也可以自行寻找其他库

RepeatMasker -pa 15 -lib fix.lib --gff merlin.fa
#会输出merlin.fa.cat.gz、merlin.fa.out、merlin.fa.out.gff

perl ConvertRepeatMasker2gff.pl merlin.fa.out merlin.Denovo.gff Denovo
#输出merlin.Denovo.gff 