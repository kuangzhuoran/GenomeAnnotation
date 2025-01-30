use warnings;
use strict;

my $dir_path = shift or die "Need LTR_harvest results dir path.\n";
my $species_name = shift or die "Need species name.\n";
my @file = <$dir_path/*/*.scn>;

open(O,">$dir_path/$species_name.harvest.scn");
#for (0..$#file) {
#    my $file = shift @file;
foreach my $file (@file) {
    $file =~ /$dir_path\/(\S+)\/\S+scn$/;
    my $fileid = $1;
    #my @a = `less $file`;
    #for(@a){
    open(my $IN, "<", $file);
    while(<$IN>){
        chomp;
        next if(/^\s*$|^#/);
        my $a = $_."  ".$fileid;
        print O "$a\n";
    }
    close $IN;
}

close O;
