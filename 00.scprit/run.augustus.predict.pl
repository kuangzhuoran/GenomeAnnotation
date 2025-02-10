#!/usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;
my ($inputdir,$outputdir,$software,$db,$perlbase)=@ARGV;
die "perl $0 inputdir outputdir software speceis perlbase\n" if (! $perlbase);

my ($max,$window,$step)=(3000000,2000000,300000);

open (SH,">$outputdir/00.running.sh");
open (SH2,">$outputdir/01.converting.sh");
my @inputfa=<$inputdir/*fa>;
for my $inputfa (@inputfa){
    $inputfa=~/\/([^\/]+)\.fa$/ or die "$inputfa\n";
    my $chr=$1;
    my $fa=Bio::SeqIO->new(-format=>"fasta",-file=>"$inputfa");
    while (my $seq=$fa->next_seq){
        my $id=$seq->id;
        my $seq=$seq->seq;
        my $len=length($seq);
        my $outputdir2="$outputdir/augustus_temp/$id";
	`mkdir -p $outputdir2` if (! -e "$outputdir2");
	print SH2 "$perlbase/utils/genscan.merge.pl $outputdir2 $outputdir/augustus_results/$id.gff\n";
	if ($len >= $max){
	    for (my $i=0;$i<$len;$i=$i+$window-$step){
                my ($s,$e)=($i,$i+$window-1);
                $e=$len if $e > $len;
                my $newseq=substr($seq,$s,$e-$s+1);
                open (O,">$outputdir2/$id.$s-$e.fa");
                print O ">$id\n$newseq\n";
                close O;
		print SH "$software --species=$db $outputdir2/$id.$s-$e.fa | perl $perlbase/utils/ConvertFormat_augustus.pl - $outputdir2/$id.$s-$e.fa.gff\n";
	    }
	}else{
	    print SH "$software --species=$db $inputfa  | perl $perlbase/utils/ConvertFormat_augustus.pl - $outputdir2/$id.0-$len.fa.gff\n";
	}
    }
}
close SH;
close SH2;


