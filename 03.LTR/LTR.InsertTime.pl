#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path getcwd cwd);

my ($genome,$name,$split,$cpu)=@ARGV;
die("Usage:\nperl $0 <Genome sequence file> <Species Name> <split LTR_retriever?(yes or no, default:no)> <Option: CPU default:4>\n") if(@ARGV<2);
if($split=~/^\d+$/){
    $cpu = $split;
    $split=undef;
}
$cpu //= 4;
$split //= "no";
die "03 will error : no LAI not cat scn" if $split eq 'yes';
`mkdir -p $name`;

my $path_ori = abs_path($genome);
`ln -s $path_ori $name/$name.genome.fna` if(!-e "$name/$name.genome.fna");
my $genome_path = cwd() . "/$name/$name.genome.fna";

`perl /beegfs/home/kuangzhuoran/workspace/ChrVar/00.merlin/0.scprit/split_fasta.pl $genome $name/split_contig no` if(! -e "$name/split_contig");
my @contig = <$name/split_contig/*.fa>;

#01 ltr_finder  # gen: 
open (O,">$name/01.$name.LTRfinder.run.sh");
`mkdir -p $name/01.LTRfinder`;
my $out_dir_path = abs_path("$name/01.LTRfinder");
print O "cd $out_dir_path; /beegfs/home/kuangzhuoran/software/LTR_FINDER_parallel/LTR_FINDER_parallel -seq $genome_path -threads $cpu -harvest_out -size 5000000 -time 3000\n";
close O;

#02 ltr_harvest # gen: 
open(O,">$name/02.$name.LTRHarvest.run.sh") || die($!);
`mkdir -p $name/02.LTRHarvest`;
$out_dir_path = abs_path("$name/02.LTRHarvest");
print O "cd $out_dir_path; perl /beegfs/home/kuangzhuoran/workspace/ChrVar/00.merlin/0.scprit/SplitRunLTRharvest.pl $genome_path /beegfs/home/kuangzhuoran/software/gt-1.5.10-Linux_x86_64-64bit-complete/bin/gt $name $cpu";
#print O "cd $out_dir_path; perl /data/01/user104/project/01.Orinus_thoroldii/02.comparative_genomics/07.LTR-RT/SplitRunLTRharvest.pl $genome_path /data/00/user/user105/software/LTR_harvest/gt-1.5.10-Linux_x86_64-64bit-complete/bin/gt $name $cpu";
close O;

#03 ltr_retriever # gen: 
open(O,">$name/03.$name.LTR_retriever.run.sh");
$out_dir_path = abs_path($name);
`mkdir -p $out_dir_path/03.LTR_retriever`;



if($split eq "yes"){
    for my $contig(@contig){
        $contig =~ /split_contig\/(\S+).fa/; my $id = $1;
        $contig = abs_path($contig);
        print O <<"EOF";
cd $out_dir_path/03.LTR_retriever
mkdir $id
cd $id
ln -s $contig $id.fna
/beegfs/home/kuangzhuoran/software/LTR_retriever/LTR_retriever -genome $id.fna -inharvest $out_dir_path/02.LTRHarvest/$id/$id.harvest.scn -infinder $out_dir_path/01.LTRfinder/$name.genome.fna.finder.combine.scn -threads $cpu
EOF
    }
}else{ # no split
    my $id = $name;
    print O "cd $out_dir_path/03.LTR_retriever\n";
    print O qq`cat $out_dir_path/01.LTRfinder/$name.genome.fna.finder.combine.scn $out_dir_path/02.LTRHarvest/$id.harvest.scn > $out_dir_path/03.LTR_retriever/$id.merged.scn \n`;
    print O "ln -s $genome_path $name.genome.fna; 
    /beegfs/home/kuangzhuoran/software/LTR_retriever/LTR_retriever -genome $name.genome.fna -inharvest $out_dir_path/03.LTR_retriever/$id.merged.scn -threads $cpu\n";
}
close O;


# final merge
open(O,">$name/$name.retriever.sh") || die($!);
print O << "EOF";
#!/usr/bin/sh
source /beegfs/home/kuangzhuoran/miniconda3/bin/activate && conda activate zhuoran
sh $out_dir_path/01.$name.LTRfinder.run.sh
sh $out_dir_path/02.$name.LTRHarvest.run.sh
sh $out_dir_path/03.$name.LTR_retriever.run.sh\n";
EOF
close O;

# change to extcutable
`chmod 755 $name/$name.retriever.sh`;
#`chmod 777 $name`; 
#`chmod 777 $name/01.LTRfinder`; 
#`chmod 777 $name/02.LTRHarvest`; 
#`chmod 777 $name/03.LTR_retriever`;

