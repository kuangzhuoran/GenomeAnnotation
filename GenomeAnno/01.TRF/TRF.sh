#安装Tandem Repeats Finder
#http://tandem.bu.edu/trf/trf.html

#不需要进行软屏蔽
trf merlin.fa 2 7 7 80 10 50 500 -f -d -m
perl  ConvertTrf2Gff.pl  merlin.fa.2.7.7.80.10.50.500.dat merlin.TRF.gff