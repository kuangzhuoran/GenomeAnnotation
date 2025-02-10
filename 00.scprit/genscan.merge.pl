#!/usr/bin/perl
use strict;
use warnings;

my ($indir,$outfile)=@ARGV;
die "perl $0 indir outfile\n" if ! $outfile;

my %sh;
my $chr;
my @in=<$indir/*gff>;
for my $in (@in){
    $in=~/\/([^\/]+)\/[^\/]+\.(\d+)-(\d+).fa.gff$/ or die "$_\n";
    my $start=$2;
    $chr=$1;
    $sh{$chr}{$start}=$in;
}
close F;

my %gff;
for my $k1 (sort keys %sh){
    for my $k2 (sort keys %{$sh{$k1}}){
	my $ingff=$sh{$k1}{$k2};
	my $line=0;
	my ($genes,$genee,$id);
	open (F,"$ingff");
	while (<F>){
	    chomp;
	    $line++;
	    my @a=split(/\s+/,$_);
	    ($a[0],$a[3],$a[4])=($chr,$a[3]+$k2,$a[4]+$k2);
	    if ($a[2] eq 'gene'){
		($genes,$genee)=($a[3],$a[4]);
		$id="$a[0]-$a[3]-$a[4]";
		$id="NA" if exists $gff{$a[6]}{$genes}{$genee}{gff}{$id};
	    }
	    next if $id eq 'NA';
	    $gff{$a[6]}{$genes}{$genee}{id}=$id;
	    $gff{$a[6]}{$genes}{$genee}{gff}{$id}{$line}=join("\t",@a);
	    $gff{$a[6]}{$genes}{$genee}{cds}{$id} += abs($a[4]-$a[3])+1 if $a[2]=~/^cds$/i;
	    #print "\$gff{$a[6]}{$genes}{$genee}{cds}{$id} += abs($a[4]-$a[3])+1\n" if $a[2]=~/^cds$/i; 
	}
	close F;
    }
}


my $genenum=0;
open (O,">$outfile")||die"cannot creat $outfile\n";
for my $k1 (sort keys %gff){
    my ($olds,$olde)=(-1,-1);
    my @k2=sort{$a<=>$b} keys %{$gff{$k1}};
    for (my $i=0;$i<@k2;$i++){
	my @k3=sort{$b<=>$a} keys %{$gff{$k1}{$k2[$i]}};
	my $k3=$k3[0];
	if ($i == 0){
	    ($olds,$olde)=($k2[$i],$k3[0]);
	}else{
	    my $len1=$olde-$olds+1;
	    my $len2=$k3[0]-$k2[$i]+1;
	    my ($as,$ae,$bs,$be)=sort{$a<=>$b} ($olds,$olde,$k2[$i],$k3[0]);
	    if ($ae != $olde){
		if ($len2>$len1){
		    ($olds,$olde)=($k2[$i],$k3[0]);
		}
	    }else{
		my $k4=$gff{$k1}{$olds}{$olde}{id};
		#print "\$gff{$k1}{$olds}{$olde}{cds}{$k4}\n";exit;
		if ($gff{$k1}{$olds}{$olde}{cds}{$k4} >= 150){
		    $genenum++;
		    for my $k5 (sort{$a<=>$b} keys %{$gff{$k1}{$olds}{$olde}{gff}{$k4}}){
			my @gffline=split(/\s+/,$gff{$k1}{$olds}{$olde}{gff}{$k4}{$k5});
			$gffline[8]=~s/_g\d+/_g$genenum/g;
			print O join("\t",@gffline),"\n";
		    }
		}
		($olds,$olde)=($k2[$i],$k3[0]);
	    }
	}
    }
    if ($olds != $k2[-1]){
	my @k3=sort{$b<=>$a} keys %{$gff{$k1}{$k2[-1]}};
	my $k3=$k3[0];
	my ($as,$ae,$bs,$be)=sort{$a<=>$b} ($olds,$olde,$k2[-1],$k3[0]);
	if ($ae != $olde){
	    next;
	}else{
	    my $k4=$gff{$k1}{$k2[-1]}{$k3[0]}{id};
	    next if $gff{$k1}{$k2[-1]}{$k3[0]}{cds}{$k4} < 150;
	    $genenum++;
	    for my $k5 (sort{$a<=>$b} keys %{$gff{$k1}{$k2[-1]}{$k3[0]}{gff}{$k4}}){
		my @gffline=split(/\s+/,$gff{$k1}{$k2[-1]}{$k3[0]}{gff}{$k4}{$k5});
		$gffline[8]=~s/_g\d+/_g$genenum/g;
		print O join("\t",@gffline),"\n";
	    }
	}
    }
}
close O;
