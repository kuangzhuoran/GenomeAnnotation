#!/usr/bin/env perl
#===============================================================================
#
#         FILE: gff2bed_type.pl
#
#        USAGE: ./gff2bed_type.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Zeyu Zheng (LZU), zhengzy2014@lzu.edu.cn
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 03/15/2021 10:54:49 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use zzIO;
use v5.24;

my ($out_dir, @ins) = @ARGV;


#$out='-';

mkdir $out_dir or die unless -e $out_dir;
my $out_summary = "$out_dir/99.SUMMARY";
my $out_summary2 = "$out_dir/99.SUMMARY2";
my $out_summary3 = "$out_dir/99.SUMMARY3";
my $OSUM = open_out_fh($out_summary);
my $OSUM2 = open_out_fh($out_summary2);
my $OSUM3 = open_out_fh($out_summary3);

my %gffs;
my %classes;

foreach my $in (@ins) {
    my $gff = &read_gff($in);
    $gffs{$in} = $gff;
    $classes{$_}++ foreach keys %$gff;
}

my $lens = &process_gff_results(\%classes, \%gffs);
foreach my $class (sort keys %$lens) {
    say $OSUM join "\t", $class, $$lens{$class};
}


my $lens2 = &lens_lens2($lens);
foreach my $class (sort keys %$lens2) {
    say $OSUM2 join "\t", $class, $$lens2{$class};
}

my $lens3 = &lens2_lens3($lens2);
foreach my $class (sort keys %$lens3) {
    say $OSUM3 join "\t", $class, $$lens3{$class};
}

exit;


sub process_gff_results {
    my %lens;
    my ($classes, $gffs) = @_;
    foreach my $class (sort keys %$classes) {
        my $class_noslash = $class;
        $class_noslash=~s#/#_#g;
        my $out = "$out_dir/$class_noslash.bed";
        open(my $R, "| sort -k1,1 -k2,2n | bedtools merge -i - > $out");
        foreach my $in (@ins) {
            next unless exists $$gffs{$in}{$class};
            my $h = $$gffs{$in}{$class};
            #say  $_ foreach @$h;
            say $R $_ foreach @$h;
        }
        close $R;
        my $IR = open_in_fh($out);
        my $len=0;
        while(<$IR>) {
            chomp;
            next unless $_;
            next if /^#/;
            my @F = split(/\t/);
            $len+=$F[2]-$F[1];
        }
        $lens{$class} = $len;
    }
    return(\%lens);
}




sub lens2_lens3 {
    my ($lens2) = @_;
    my %lens3;
    foreach my $class (sort keys %$lens2) {
        my $len = $$lens2{$class};
        if ($class=~/^(LTR|LINE|DNA)/) {
            $lens3{$1} += $len;
        }
    }
    return (\%lens3);
}

sub lens_lens2 {
    my ($lens) = @_;
    my %lens2;
    foreach my $type (sort keys %$lens) {
        my $len = $$lens{$type};
        if ($type=~/LTR/){
            if($type=~/(Gypsy|Copia)/){
                $type="LTR_".$1;
            }else{
                $type="LTR_other";
            }
        }elsif($type=~/DNA/){
            if ($type=~/(CMC-EnSpm|hAT-Ac|hAT-Tip100|MuDR|PIF-Harbinger)/){                                                                 
                $type="DNA_".$1;
            }else{
                $type="DNA_other";
            }
        }elsif($type=~/LINE/){
            if ($type=~/(L1|L2)/){
                $type="LINE_".$1;
            }else{
                $type="LINE_other";
            }
        }elsif($type=~/SINE.*/){
            $type="SINE";
        }elsif($type=~/Simple_repeat/ or $type=~/TandemRepeat/){
            $type="Simple_repeat";
        }elsif($type=~/Satellite/){
            $type="Satellite";
        }elsif($type=~/rRNA|snRNA|tRNA/){
            $type="Small_RNA";
        }elsif($type=~/Helitron/){
            $type="DNA_Helitron";
        }elsif($type=~/Low_complexity/){
            $type="Low_complexity";
        }else{
            $type="Unclassified_".$type;
        }
        $lens2{$type}+=$len;
    }
    return (\%lens2);
}




sub read_gff {
    my ($in) = (@_);
    my %ret;
    my $I = open_in_fh($in);
    while(<$I>) {
        chomp;
        next unless $_;
        next if /^#/;
        my @F = split(/\t/);
        my $class;
        if ($F[8]=~/Class=([^;]+);/ ) {
            $class = $1;
        } else {
            #say "no class found: $in : $_";
            $class = $F[2]; # TRF TandemRepeat
        }

        #$F[8]=~/ID=([^;]+);/ or die "no class found: $in : $_";
        #my $id = $1;
        #push $ret{$class}->@*, join "\t", $F[0], $F[3]-1, $F[4], $class, $id;
        push $ret{$class}->@*, join("\t", $F[0], $F[3]-1, $F[4]);
    }
    return \%ret;
}

