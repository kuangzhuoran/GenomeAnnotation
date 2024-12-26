use warnings;
use strict;
use v5.24;
use zzIO;

sub help {
	my $info = shift // '';
	die <<EOF;
perl xx.pl in_gff ID out_gff
$info
EOF
}

my ( $in_gff, $gid, $out_gff ) = @ARGV;

&help() unless defined $out_gff;

unless ($gid=~/0$/) {
	$gid.='0'x5;
}

my $I = open_in_fh($in_gff);
my $O = open_out_fh($out_gff);

my ( %g, %n, %t );
while (<$I>) {
    chomp;
    next if /^#/;
    my @l = split /\s+/, $_;
    next if @l < 2;
    if ( $l[2] eq "gene" ) {
        $gid++;
        $l[8] =~ /ID=(\S+);Name=/;
        $g{$1} = $gid;
        $l[8] = "ID=" . $gid;
		say $O join "\t", @l;
    } elsif ( $l[2] eq "mRNA" ) {
        $l[8] =~ /ID=(\S+);Parent=(\S+);Name/;
        my $t = $1;
        my $id = $2;
        my $gid = $g{$id};
        $n{$gid}++;
        my $nt = $gid . "." . $n{$gid};
        $t{$t} = $nt;
        $l[8] = "ID=" . $nt . ";Parent=" . $gid;
		say $O join "\t", @l;
    } elsif ( $l[2] eq "exon" ) {
        $l[8] =~ /ID=\S+(\.exon\d+);Parent=(\S+)/;
        my $t = $t{$2};
        my $n = $1;
        $l[8] = "ID=" . $t . $n . ";Parent=" . $t;
		say $O join "\t", @l;
    } elsif ( $l[2] eq "CDS" ) {
        $l[8] =~ /ID=cds.\S+;Parent=(\S+)/;
        my $t = $t{$1};
        $l[8] = "ID=cds." . $t . ";Parent=" . $t;
		say $O join "\t", @l;
    } else {
        die "$_\n";
    }
}
close;
