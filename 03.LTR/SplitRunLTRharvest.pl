#!/usr/bin/env perl -w
use warnings;
use strict;
use Cwd qw/abs_path getcwd cwd/;

my ($genome,$ltrharvest,$name,$threads) = @ARGV;
die "Usage:
perl $0 <genome seq> <genometools software path> <species name> <threads number(1~15), default:4>\n" if(@ARGV<3);
$threads = 4 unless ($threads);
$threads = 1 if($threads<1);
$threads = 15 if($threads >15);
`perl /beegfs/home/kuangzhuoran/workspace/ChrVar/00.merlin/0.scprit/split_fasta.pl $genome split_genome no` if(! -e "split_genome");
`mkdir -p LTRharvest` if(! -e "LTRharvest");
my @seq = <split_genome/*.fa>;

open(O,">$name.LTRHarvest.run.sh") || die($!);
my $out_path = abs_path("LTRharvest");
for my $file(@seq){
    $file =~ /split_genome\/(\S+).fa/; my $id = $1;
    $file = abs_path($file);
    print O "mkdir $out_path/$id; $ltrharvest suffixerator -db $file -indexname $out_path/$id/$id -tis -suf -lcp -des -ssp -sds -dna; $ltrharvest ltrharvest -index $out_path/$id/$id -vic 10 -seed 20 -seqids yes -similar 85 -minlenltr 100 -maxlenltr 40000 -mintsd 4 -maxtsd 6 -motif TGCA -motifmis 1 > $out_path/$id/$id.harvest.scn\n";
}
close O;

`parallel -j $threads < $name.LTRHarvest.run.sh`;
`rm -r split_genome`;
#`perl /data/01/user105/project/Ilv_genome/05.LTR_analysis/merge_LTRharvest.pl LTRharvest $name`;
`perl /beegfs/home/kuangzhuoran/workspace/ChrVar/00.merlin/0.scprit/merge_LTRharvest.pl LTRharvest $name`;
`mv LTRharvest/$name.harvest.scn .`;
`rm -rf LTRharvest`;
