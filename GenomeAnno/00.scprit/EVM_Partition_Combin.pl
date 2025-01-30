#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd 'abs_path';

my ($evm,$genome,$abinitio,$homolog,$rnaseq,$segmentSize,$overlapSize,$weight)=@ARGV;
my $helpline="perl $0 evm_dir genome abinitio homolog rnaseq segmentSize overlapSize wight_file\nevm_dir : the evm base dir that contained evidence_modeler.pl and EvmUtils\ngenome : the input scaffold.fa\nabinitio : the abinitio evidence file\nhomolog : the homolog evidence file\nrnaseq : rnaseq evidence file\nsegmentSize : segement the large scaffold into \"segmentSize\" bp\noverlapSize : overlapSize\nwight_file : full path to wight_file\n";

if (! $segmentSize){
    $segmentSize=1000000;
}
if (! $overlapSize){
    $overlapSize=$segmentSize*0.5;
}
if (! $evm || ! $abinitio || ! $homolog || ! $rnaseq || ! $segmentSize || ! $overlapSize){
    print "$helpline";
    exit;
}

my $pwd=`pwd`;chomp $pwd;
print "cd $pwd ; $evm/EvmUtils/partition_EVM_inputs.pl --genome $genome --gene_predictions $abinitio --protein_alignments $homolog --transcript_alignments $rnaseq --segmentSize $segmentSize --overlapSize $overlapSize --partition_listing partitions_list.out; $evm/EvmUtils/write_EVM_commands.pl --genome  $genome --weights $weight --gene_predictions $abinitio --protein_alignments $homolog --transcript_alignments $rnaseq --output_file_name evm.out  --partitions partitions_list.out >  commands.list; cd -\n";
#print "parallel -j 20 < commands.list\n";
#print "$evm/vmUtils/recombine_EVM_partial_outputs.pl --partitions partitions_list.out --output_file_name evm.out\n";
