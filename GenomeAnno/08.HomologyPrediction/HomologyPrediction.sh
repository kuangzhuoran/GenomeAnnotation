#首先从NCBI上下载多个近缘物种或者模式物种的基因组和注释
#每个物种都要重复这个过程，这里只展示一个物种
./datasets download genome accession GCF_016699485.2 --include gff3,genome --filename GCF_016699485.2.zip
#注意是gff3而非gtf，也非gff2

#然后提取最长转录本
perl gff_filter_longest.pl GCF_016699485.2.gff longestID GCF_016699485.2.longest.gff

#运行GeMoMa
java -Xmx70G -jar ./GeMoMa-1.9.jar CLI GeMoMaPipeline threads=20 t=merlin.softmasked.fa s=own g=GCF_016699485.2.fna a=GCF_016699485.2.longest.gff outdir=result AnnotationFinalizer.r=NO tblastn=false

#会生成一个文件夹result
#里面的final_annotation.gff就是同源注释的结果

mv final_annotation.gff GCF_016699485.2.gff
perl ConvertFormat_GeMoMa.pl  GCF_016699485.2.gff
#输出GCF_016699485.2.gff.for.evm


cat GCF_016699485.2.gff.for.evm GCF_023634085.1.hap2.gff.for.evm... > merlin.homology.gff
#将多个物种的结果合并
#这里就是EVM最后用到的文件了