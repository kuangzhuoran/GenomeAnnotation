#此时，我们有4个注释文件：
#merlin.TE.gff, merlin.TP.gff, merlin.Denovo.gff以及merlin.TRF.gff
#统计
cat  merlin.TE.gff  merlin.TP.gff  merlin.Denovo.gff  merlin.TRF.gff | awk '{print $1"\t"$4-1"\t"$5}' | bedtools sort -i - | bedtools merge -i - > merlin.repeat.merge.bed
awk '{print $3-$2}' merlin.repeat.merge.bed | awk '{sum += $1};END {print sum}'






####以下可以忽略
#将这4个gff文件都软连接同一个文件夹中，比如：
mkdir RepeatMerge
ln -s ......
#然后重命名，把merlin.的前缀去掉
mv merlin.Denovo.gff Denovo.gff
mv merlin.TRF.gff TRF.gff
mv merlin.TE.gff TE.gff
mv merlin.TP.gff TP.gff

#现在我们有4个文件：
#TE.gff, TP.gff, TRF.gff, Denovo.gff

perl Repeat_ClassStatisitc/Util/TypeBed.pl > All.repeat.type.sort.bed
perl Repeat_ClassStatisitc/Util/SplitBed.pl All.repeat.type.sort.bed

#cpan MCE::Loop #安装
perl Repeat_ClassStatisitc/Util/CreatRepeatChart.pl 10 > RepeatStatistic.txt
perl Repeat_ClassStatisitc/Util/RateRepeat.pl 1178217087 RepeatStatistic.txt | tee 0.step1.txt
#1178217087是基因组的长度

perl Repeat_ClassStatisitc/Util/SplitGff3.pl ./
perl Util/ClassStatisticByContig.pl 10
perl Util/MergeClassRes.pl 1178217087 124310090 | tee 0.step2.txt
#1178217087是基因组的长度
#124310090是重复序列的长度: awk '{sum += $6};END {print sum}' RepeatStatistic.txt