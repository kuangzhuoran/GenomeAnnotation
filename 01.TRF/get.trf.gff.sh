#Tandem Repeats Finder
#不需要进行软屏蔽
trf genome.fasta 2 7 7 80 10 50 500 -f -d -m
perl  ConvertTrf2Gff.pl  merlin.hap2.fa.2.7.7.80.10.50.500.dat  genome.trf.gff