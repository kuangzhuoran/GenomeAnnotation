#我使用的是EVidenceModeler-v2.1.0
#v1的命令行和参数有所不同

#同源注释的gff,PROTEIN
#merlin.homology.gff

#转录组注释得到的gff有：
#transcripts.fasta.transdecoder.genome.gff3，此部分属于OTHER_PREDICTION
#merlin.sqlite.pasa_assemblies.gff3，属于TRANSCRIPT

#合并不同的从头预测的gff,ABINITIO_PREDICTION
cat  merlin.chicken.denovo.gff  merlin.busco.denovo.gff merlin.helixer.gff3 transcripts.fasta.transdecoder.genome.gff3...> merlin.denovo.gff


/path/to/EVidenceModeler --sample_id merlin --genome merlin.softmasked.fa --gene_predictions merlin.denovo.gff --protein_alignment merlin.homology.gff \
    --transcript_alignments merlin.sqlite.pasa_assemblies.gff3 --segmentSize 200000 --overlapSize 30000 --weights weights.txt --CPU 30



#cat weights.txt
#权重文件的内容
TRANSCRIPT	PASA_transcript_assemblies	20
PROTEIN	GeMoMa	10
OTHER_PREDICTION	transdecoder	20
ABINITIO_PREDICTION	Helixer	2
ABINITIO_PREDICTION	chicken	2
ABINITIO_PREDICTION	human	1
ABINITIO_PREDICTION	busco	3