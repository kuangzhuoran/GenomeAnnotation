#!/usr/bin/perl
use strict;
use warnings;

my ($inputdir,$outputdir,$software,$db,$phase_pl)=@ARGV;
die "perl $0 inputdir outputdir software speceis phased_pl\n" if (! $phase_pl);

my @in=<$inputdir/*fa>;
for my $in (@in){
    $in=~/\/([^\/]+)\.fa$/;
    my $chr=$1;
    print "$software $in -d $db -g | perl $phase_pl - $outputdir/$chr.gff\n";
}

