#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';

my ($evm_dir,$genome_dir,$rundir,$base)=@ARGV;
die "perl $0 evm_dir genome_dir rundir base\n" if (! $base);

my $weights="$rundir/evm.weights.txt";
$weights=abs_path("$weights");
$weights=~/^(\S+)\/03.gene_predict\/04.evm/ or die "$weights";
my @chrfa=<$genome_dir/*fa>;
for my $chrfa (@chrfa){
    $chrfa=~/\/([^\/]+)\.fa$/ or die "$chrfa\n";
    my $chr=$1;
    print  "cd $rundir/evm_for_each_chr/$chr ; perl $base/EVM_Partition_Combin.pl $evm_dir $genome_dir/$chr.fa ab_initio.gff homolog.gff rna_seq.gff 1000000 100000 $weights > split_evm_running.sh ; cd ../../\n";
}
