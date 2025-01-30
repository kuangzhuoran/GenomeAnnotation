#!/usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;

#my $genscan_param=shift;      #"/home/data_disk_38T/luzhiqiang_work/software/genscan/Arabidopsis.smat";
#my $genscan=shift;            #"/home/data_disk_38T/luzhiqiang_work/software/genscan/genscan";
#my $perlbases=shift;          #"/home/data_disk_38T/luzhiqiang_work/program/gene_prediction/scripts";

my ($genscan_param,$genscan,$perlbases,$input_dir,$outputdir)=@ARGV;
die "perl $0 genscan_param genscan perlbases inputdir outputdir windowsize stepsize\n" if (! $outputdir);

my ($max,$window,$step)=(5000000,3000000,300000);

open (SH,">$outputdir/00.running.sh");
open (SH2,">$outputdir/01.converting.sh");
my @inputfa=<$input_dir/*fa>;
for my $inputfa (@inputfa){
    my $fa=Bio::SeqIO->new(-format=>"fasta",-file=>"$inputfa");
    while (my $seq=$fa->next_seq){
	my $id=$seq->id;
	my $seq=$seq->seq;
	my $len=length($seq);
	my $outputdir2="$outputdir/genscan_temp/$id";
	`mkdir -p $outputdir2` if (! -e "$outputdir2");
	print SH2 "$perlbases/genscan.merge.pl $outputdir2 $outputdir/genscan_results/$id.gff\n";
	if ($len >= $max){
	    for (my $i=0;$i<$len;$i=$i+$window-$step){
		my ($s,$e)=($i,$i+$window-1);
		$e=$len if $e > $len;
		my $newseq=substr($seq,$s,$e-$s+1);
		open (O,">$outputdir2/$id.$s-$e.fa");
		print O ">$id\n$newseq\n";
		close O;
		print SH "$genscan $genscan_param $outputdir2/$id.$s-$e.fa | $perlbases/ConvertFormat_genscan.pl - > $outputdir2/$id.$s-$e.fa.gff\n";
	    }
	}else{
	    print SH "$genscan $genscan_param $inputfa | $perlbases/ConvertFormat_genscan.pl - > $outputdir2/$id.0-$len.fa.gff\n";
	}
    }
}
close SH;
close SH2;
