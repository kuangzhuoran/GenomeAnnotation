#!/usr/bin/perl
use strict;
use warnings;

my $dir=shift or die "inputdir && EVM_dir\n";
my $evm_dir=shift or die "inputdir && EVM_dir\n";
my @in=`ls $dir`;
for my $in (@in){
    chomp $in;
    print "cd $dir/$in; $evm_dir/EvmUtils/recombine_EVM_partial_outputs.pl --partitions partitions_list.out --output_file_name evm.out ; ln -s $in/evm.out . ; $evm_dir/EvmUtils/EVM_to_GFF3.pl evm.out $in > evm.out.gff ; cd ../../../../\n";
}
