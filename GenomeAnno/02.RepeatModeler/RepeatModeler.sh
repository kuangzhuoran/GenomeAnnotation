RepeatModeler-2.0.3/BuildDatabase -name merlin merlin.fa  #这里也可以用多个基因组同时建库,比如用所有鸟类基因组
RepeatModeler-2.0.3/RepeatModeler -database merlin -pa 15 -LTRStruct -engine rmblast > merlin.out
#会输出merlin.out、merlin-families.fa、merlin-families.stk
#同时会生成一个类似RM_16144.SatDec211808382024，RM*的文件夹
#这个文件夹内部有一个文件叫做consensi.fa.classified要用到
#这个就是我们自己建的库



cat RebBase RM_16144.SatDec211808382024/consensi.fa.classified > fix.lib
#我们这里把Repbase和我们自己建的库合并
RepeatMasker -pa 15 -lib fix.lib --gff merlin.fa
#会输出merlin.fa.cat.gz、merlin.fa.out、merlin.fa.out.gff

perl ConvertRepeatMasker2gff.pl merlin.fa.out merlin.Denovo.gff Denovo
#这里得到的merlin.Denovo.gff就是后续用到的注释文件,同其他重复序列注释合并然后去冗余
#一般做到这也就可以了


#我们这里再多跑一步LTR，见03.LTR
#用我们自己建的库和RepBase 加上 LTR新产生的库，这3个库，再次进行搜索
