#同源搜索
RepeatMasker -pa 30 -nolow -norna -no_is -gff -species aves merlin.fa


perl ConvertRepeatMasker2gff.pl merlin.fa.out merlin.TE.gff TE
#生成的merlin.TE.gff就是后续用到的注释文件,同其他重复序列注释合并然后去冗余
#做到这就够了