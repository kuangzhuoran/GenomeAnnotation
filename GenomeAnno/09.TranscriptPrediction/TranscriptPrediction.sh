#安装hisat、stringtie、TransDecode和PASA，conda就可以

#第一步，对参考基因组建立索引
hisat2-build merlin.fa merlin

#第二步，如果有多个转录组数据，就重复多次
hisat2 --new-summary -p 10 -x merlin -1 heart.R1.clean.fq.gz -2 heart.R2.clean.fq.gz | samtools view --threads 10 -Sb > heart.bam
samtools sort -O bam -@ 10 -o heart.sort.bam heart.bam

#合并多个组织的bam
samtools merge -@ 10 merge.bam heart.sort.bam blood.sort.bam liver.sort.bam......


#第三步，使用stringtie组装并提取转录本
stringtie -p 10 -o merged.gtf merge.bam

#第四步，transdecoder做基因预测（此部分属于other prediction）
gtf_to_alignment_gff3.pl merged.gtf > transcripts.gff3
gtf_genome_to_cdna_fasta.pl merged.gtf  merlin.fa  > transcripts.fasta
TransDecoder.LongOrfs -t transcripts.fasta
TransDecoder.Predict -t transcripts.fasta
cdna_alignment_orf_to_genome_orf.pl transcripts.fasta.transdecoder.gff3  transcripts.gff3   transcripts.fasta  > transcripts.fasta.transdecoder.genome.gff3
#输出的transcripts.fasta.transdecoder.genome.gff3就是后面EVM用的东西

#第五步，做pasapipeline
seqclean  transcripts.fasta
#得到transcripts.fasta.clean

#实测发现除了conda安装，还是需要下载PASA
#git clone https://github.com/PASApipeline/PASApipeline.git
#但是仅仅下载即可，然后把软件改成全路径，就行
/path/to/PASA/Launch_PASA_pipeline.pl  -c alignAssembly.config -C -R -g merlin.fa  -t transcripts.fasta.clean -T -u transcripts.fasta --ALIGNERS blat,gmap --CPU 20

#输出的merlin.sqlite.pasa_assemblies.gff3就是后面EVM用的东西