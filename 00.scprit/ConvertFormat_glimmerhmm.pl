#! /usr/bin/env perl
use strict;
use warnings;

my ( $input, $output ) = @ARGV;

die "perl $0 input output\n" if !$output;

my %gff;
my $geneid;
open( I, "< $input" ) or die "Cannot open $input";
while (<I>) {
    chomp;
    next if (/^#/);
    next if /^$/;
    my @a = split(/\t/);
    next if scalar(@a) < 8;
    $a[1] = lc( $a[1] );
    if ( $a[2] eq 'mRNA' ) {
        my @b = @a;
        $b[8] =~ s/gene(\d+);\S+/GENE$1/;
        $b[2] = "gene";
        $geneid = "$a[0]-$a[8]";
        $gff{$geneid}{gff} .= join( "\t", @b ) . "\n";

        #print O join("\t",@b),"\n";
        $a[8] =~ s/;Name=(.+\.path\d+)\.gene(\d+)/;Parent=$1.GENE$2/ or die "Error! $a[8]";

        #print O join("\t",@a),"\n";
        $gff{$geneid}{gff} .= join( "\t", @a ) . "\n";
    } elsif ( $a[2] eq 'CDS' ) {
        my @b = @a;
        $b[2] = 'exon';
        $b[8] =~ s/ID=.+\.cds\d+\.(\d+);Parent=(.+\.path\d+\.gene\d+);Name=\S+/ID=$2.exon$1;Parent=$2/;

        #print O join("\t",@b),"\n";
        $gff{$geneid}{gff} .= join( "\t", @b ) . "\n";
        $a[8]
            =~ s/ID=.+\.cds\d+\.(\d+);Parent=(\w+.path\d+.gene\d+);Name=\S+/ID=cds.$2;Parent=$2/;

        #print O join("\t",@a),"\n";
        $gff{$geneid}{gff} .= join( "\t", @a ) . "\n";
        $gff{$geneid}{len} += abs( $a[4] - $a[3] ) + 1;
    }
}
close I;
close O;
open( O, "> $output" ) or die "Cannot create $output";
for my $k ( sort keys %gff ) {
    print O "$gff{$k}{gff}" if ( $gff{$k}{len} >= 50 );
}
close O;
