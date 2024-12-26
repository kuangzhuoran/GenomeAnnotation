#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use Bio::SeqIO;
use v5.10;
use File::Basename;

### Created by Yang Yongzhi. 2019.12.10 ###
### add LTR retriever by Zheng Zeyu. 2020.12.10 ###

my ($config,$step);
GetOptions(
           'config=s' => \$config,
           'step=s' => \$step,
          );
if ((! $config) || (! $step)){
    &say_help;
    exit;
}


sub say_help{
    say STDERR << "EOF";
gene annotation pipeline, version: gene_annot_lzu_v2

Usage: perl gene_predict.pl --config <config file> --step <number of running>
  
Options:
--config    giving the config file with all needed things
--step      1 represent running repeat only; 2 represent running gene prediction only.
EOF
}


my %config=&read_conf;
my $base=abs_path($0);
$base=~s/\/gene_predict.v2.pl$// or die "wrong perl script name of $0\n";

#$config{genome}=abs_path("$config{genome}");
my $genome_basename=basename $config{genome};

# split genome and masked genome
my @tmpsplit_fa;
push @tmpsplit_fa,$config{genome};
if (exists $config{masked_genome}){
    if (-e "$config{masked_genome}"){
	#$config{masked_genome}=abs_path($config{masked_genome});
	push @tmpsplit_fa,$config{masked_genome};
    }
}
for my $tmpsplit_fa (@tmpsplit_fa){
    `perl $base/utils/split_fasta.pl $tmpsplit_fa $tmpsplit_fa-split no`;# if ! -e "$tmpsplit_fa-split";
}

if ($step == 1){
    ## step 1: Repeat
    `mkdir 02.repeat_prediction` if (! -e "02.repeat_prediction");
    open (REP,">02.repeat_prediction.sh");

    ### 01.repeatmodeler
    my $tmpdir="02.repeat_prediction/01.repeatmodeler";
    `mkdir $tmpdir` if (! -e "$tmpdir");
    say REP "cd $tmpdir ; sh 00.running.sh; cd ../../\n";
    `ln -s $config{genome} $tmpdir/`;
    open (O,">$tmpdir/00.running.sh")||die"$!";
    say O <<"EOF";
$config{BuildDatabase} -name $config{species_abbreviation} $genome_basename
$config{RepeatModeler} -pa $config{threads} -database $config{species_abbreviation}
ln -s RM*/consensi.fa.classified custom.lib
$config{RepeatMasker} -pa $config{threads} -lib ./custom.lib $genome_basename
perl $base/utils/ConvertRepeatMasker2gff.pl $genome_basename.out Denovo.gff Denovo
EOF
    close O;

    ### 01.fix LTR using ltr_retriever and RepeatMasker
    $tmpdir="02.repeat_prediction/01.repeatmodeler.fix";
    `mkdir $tmpdir` if (! -e "$tmpdir");
    say REP "cd $tmpdir ; sh 00.running.sh; cd ../../";
    `ln -s $config{genome} $tmpdir/`;
    open (O,">$tmpdir/00.running.sh")||die"$!";
    say O << "EOF";
perl $base/utils/LTR.InsertTime.pl $genome_basename LTRretriever no $config{threads}
sh LTRretriever/LTRretriever.retriever.sh
ln -s LTRretriever/03.LTR_retriever/LTRretriever.genome.fna.mod.LTRlib.redundant.fa .
ln -s ../01.repeatmodeler/custom.lib .
cat custom.lib LTRretriever.genome.fna.mod.LTRlib.redundant.fa $config{RepeatMaskerLib} > custom.lib.fix.fa
$config{RepeatMasker} -pa $config{threads} -lib ./custom.lib.fix.fa $genome_basename
perl $base/utils/ConvertRepeatMasker2gff.pl $genome_basename.out Denovo.gff Denovo
EOF
    close O;

    ### 02.RepeatMasker
    $tmpdir="02.repeat_prediction/02.repeatmakser";
    `mkdir $tmpdir` if (! -e "$tmpdir");
    say REP "cd $tmpdir ; sh 00.running.sh; cd ../../";
    open (O,">$tmpdir/00.running.sh")||die"$!";
    `ln -s $config{genome} $tmpdir/`;
    say O << "EOF";
$config{RepeatMasker} -pa $config{threads} -pa $config{threads} -nolow -norna -no_is -gff -species $config{repeat_species} $genome_basename
perl $base/utils/ConvertRepeatMasker2gff.pl $genome_basename.out TE.gff TE
EOF
    close O;

    ### 03.RepeatProteinMask
    $tmpdir="02.repeat_prediction/03.repeatproteinmask";
    `mkdir $tmpdir` if (! -e "$tmpdir");
    say REP "cd $tmpdir ; sh 00.running.sh; cd ../../\n";
    open (O,">$tmpdir/00.running.sh")||die"$!";
    `ln -s $config{genome} $tmpdir/`;
    say O <<"EOF";
$base/utils/split_fasta.pl $genome_basename split_by_scaffold
for i in split_by_scaffold/* ; do echo $config{RepeatProteinMask} -noLowSimple -pvalue 1e-04 \$i ; done > 02.split.running.sh
parallel -j $config{threads} < 02.split.running.sh
cat split_by_scaffold/*annot > $genome_basename.repeatproteinmasker.annot
rm -r split_by_scaffold
perl $base/utils/ConvertRepeatMasker2gff.pl $genome_basename.repeatproteinmasker.annot TP.gff TP
EOF
    close O;

    ### 04.TRF
    $tmpdir="02.repeat_prediction/04.trf";
    `mkdir $tmpdir` if (! -e "$tmpdir");
    say REP "cd $tmpdir ; sh 00.running.sh; cd ../../\n";
    open (O,">$tmpdir/00.running.sh")||die"$!";
    `ln -s $config{genome} $tmpdir/`;
    say O << "EOF";
$config{trf} $genome_basename 2 7 7 80 10 50 2000 -d -h
perl $base/utils/ConvertTrf2Gff.pl $genome_basename.2.7.7.80.10.50.2000.dat $genome_basename.trf.gff\n
EOF
    close O;

    ### 05.Merge
    $tmpdir="02.repeat_prediction/05.merge";
    `mkdir $tmpdir` if (! -e "$tmpdir");
    say REP "cd $tmpdir ; sh 00.running.sh; cd ../../\n";
    open (O,">$tmpdir/00.running.sh")||die"$!";
    `ln -s $config{genome} $tmpdir/`;
    say O << "EOF";
cd $tmpdir
#ln -s ../01.repeatmodeler/Denovo.gff ./Denovo.gff
ln -s ../01.repeatmodeler.fix/Denovo.gff ./Denovo.gff
ln -s ../02.repeatmakser/TE.gff ./TE.gff
ln -s ../03.repeatproteinmask/TP.gff ./TP.gff
ln -s ../04.trf/$genome_basename.trf.gff ./TRF.gff
cat Denovo.gff TE.gff TP.gff TRF.gff | grep -v -P '^#' | cut -f 1,4,5 | sort -k1,1 -k2,2n -k3,3n > All.repeat.bed
bedtools merge -i All.repeat.bed > All.repeat.merge.bed
bedtools maskfasta -fi $genome_basename -bed All.repeat.merge.bed -fo $genome_basename.mask
bedtools maskfasta -fi $genome_basename -bed All.repeat.merge.bed -fo $genome_basename.mask_soft -soft

grep -v 'Class=Unknown;' Denovo.gff > Denovo.gff.known
grep -v 'Class=Unknown;' TE.gff > TE.gff.known
grep -v 'Class=Unknown;' TP.gff > TP.gff.known
grep -v 'Class=Unknown;' TRF.gff > TRF.gff.known


#bedtools intersect -b Denovo.gff -a TRF.gff.known > TRF.gff.known.noDenovo
#bedtools intersect -b Denovo.gff -a TP.gff.known > TP.gff.known.noDenovo
#bedtools intersect -b Denovo.gff -a TE.gff.known > TE.gff.known.noDenovo

perl /data/01/user101/project/cor/2.anno/CFA/02.repeat_prediction/05.merge/bed_intersect.pl TRF.gff.known Denovo.gff.known TRF.gff.known.noDenovo
perl /data/01/user101/project/cor/2.anno/CFA/02.repeat_prediction/05.merge/bed_intersect.pl TP.gff.known Denovo.gff.known TP.gff.known.noDenovo
perl /data/01/user101/project/cor/2.anno/CFA/02.repeat_prediction/05.merge/bed_intersect.pl TE.gff.known Denovo.gff.known TE.gff.known.noDenovo

perl /data/00/user/user101/software/gene_annot_lzu_v2/utils//gff_rep_summary.pl final_rep_dir Denovo.gff.known TE.gff.known.noDenovo TRF.gff.known.noDenovo  TP.gff.known.noDenovo
perl /data/00/user/user101/bin/lenbed.pl All.repeat.merge.bed > All.repeat.merge.bed.len
cat final_rep_dir/99.SUMMARY2 final_rep_dir/99.SUMMARY3 All.repeat.merge.bed.len > SUMMARY.FINAL.txt

EOF
    close REP;
        
    say "!!!Step 1: Creating repeat annotation associated files done. You can just typing `sh ./02.repeat_prediction.sh` or split the sh command and running by yourself!!\n";
} elsif($step == 2) {
    #die "no masked_genome or file not exists!" unless -e $config{masked_genome};
    # step 2: gene prediction
    if(exists $config{masked_genome} && -e $config{masked_genome}){
        my $tmpdir="03.gene_predict";
        `mkdir $tmpdir` if (! -e "$tmpdir");
        ## 01 abinitio gene prediction
        open (AB,">03.gene_predict.01.abinitio.sh");
        $tmpdir="03.gene_predict/01.abinitio";
        `mkdir $tmpdir` if (! -e "$tmpdir");
        #### 01.1 augustus
        $tmpdir="03.gene_predict/01.abinitio/augustus";
        `mkdir $tmpdir` if (! -e "$tmpdir");
        `mkdir $tmpdir/augustus_results` if (! -e "$tmpdir/augustus_results");
        `mkdir $tmpdir/augustus_temp` if (! -e "$tmpdir/augustus_temp");
        `perl $base/utils/run.augustus.predict.pl $config{masked_genome}-split $tmpdir $config{augustus} $config{augustus_train} $base`;
        say AB "##ab-initio \n\n ###augustus \n parallel -j $config{threads} < 03.gene_predict/01.abinitio/augustus/00.running.sh ; parallel -j $config{threads} < 03.gene_predict/01.abinitio/augustus/01.converting.sh \n";
        #### 01.2 genscan
        $tmpdir="03.gene_predict/01.abinitio/genscan";
        `mkdir -p $tmpdir` if (! -e "$tmpdir");
        `mkdir $tmpdir/genscan_results` if (! -e "$tmpdir/genscan_results");
        `mkdir $tmpdir/genscan_temp` if (! -e "$tmpdir/genscan_temp");
        `perl $base/utils/genscan.split.window.step.pl $config{genscan_train} $config{genscan} $base/utils $config{masked_genome}-split $tmpdir`;
        say AB "###genscan \n parallel -j $config{threads} < 03.gene_predict/01.abinitio/genscan/00.running.sh ; parallel -j $config{threads} < 03.gene_predict/01.abinitio/genscan/01.converting.sh \n";
        ### 01.3 glimmerhmm
        $tmpdir="03.gene_predict/01.abinitio/glimmerhmm";
        `mkdir -p $tmpdir` if (! -e "$tmpdir");
        `mkdir $tmpdir/glimmerhmm_results` if (! -e "$tmpdir/glimmerhmm_results");
        `perl $base/utils/run.glimmerhmm.predict.pl $config{masked_genome}-split $tmpdir/glimmerhmm_results $config{glimmerhmm} $config{glimmerhmm_train} $base/utils/ConvertFormat_glimmerhmm.pl > 03.gene_predict/01.abinitio/glimmerhmm/00.running.sh`;
        say AB "###glimmerhmm \n parallel -j $config{threads} < 03.gene_predict/01.abinitio/glimmerhmm/00.running.sh \n";
        close AB;
    }
    ### 02 homologs by GeMoMaPipeline
    open (HO,">03.gene_predict.02.homologs.sh");
    my $tmpdir="03.gene_predict/02.homologs/GeMoMa";
    `mkdir -p $tmpdir` if (! -e "$tmpdir");
    #### 02.1 run GeMoMaPipeline
    $config{homologs_dir}=abs_path($config{homologs_dir});
    my @homologs_species=split(/;/,$config{homologs_species});
    open (HOMOSH,">03.gene_predict/02.homologs/GeMoMa/00.running.sh");
    for my $homologs_species (@homologs_species){
	say HOMOSH "java -jar $config{gemoma} CLI GeMoMaPipeline threads=$config{threads} t=$config{genome} s=own g=$config{homologs_dir}/$homologs_species.genome.fa a=$config{homologs_dir}/$homologs_species.genomic.gff outdir=03.gene_predict/02.homologs/GeMoMa/$homologs_species.results AnnotationFinalizer.r=NO tblastn=false ; perl $base/utils/ConvertFormat_GeMoMa.pl 03.gene_predict/02.homologs/GeMoMa/$homologs_species.results/final_annotation.gff \n";
    }
    close HOMOSH;
    say HO "\n ##homologs \n sh 03.gene_predict/02.homologs/GeMoMa/00.running.sh \n";
    close HO;

    ### 03 EVM
    open (EVM,">03.gene_predict.04.EVM.sh");
    $tmpdir="03.gene_predict/04.evm";
    `mkdir -p $tmpdir` if (! -e "$tmpdir");
    #### 03.1 prepare and run
    my $trans="NA";
    $trans=$config{rna_seq_dir} if exists $config{rna_seq_dir};
    say EVM "$base/utils/EVM.prepare.pl $config{EVM} 03.gene_predict/01.abinitio 03.gene_predict/02.homologs/GeMoMa NA $config{genome}-split 03.gene_predict/04.evm \n";
    say EVM "$base/utils/EVM.run.cmd.pl $config{EVM} $config{genome}-split 03.gene_predict/04.evm $base/utils > 03.gene_predict/04.evm/01.split_prepare.sh \n";
    say EVM "parallel -j $config{threads} < 03.gene_predict/04.evm/01.split_prepare.sh \n";
    say EVM "cat 03.gene_predict/04.evm/evm_for_each_chr/*/split_evm_running.sh > 03.gene_predict/04.evm/02.split_run.sh \n";
    say EVM "parallel -j $config{threads} < 03.gene_predict/04.evm/02.split_run.sh \n";
    say EVM "cat 03.gene_predict/04.evm/evm_for_each_chr/*/commands.list > 03.gene_predict/04.evm/03.running.sh \n";
    say EVM "parallel -j $config{threads} < 03.gene_predict/04.evm/03.running.sh \n";
    say EVM "perl $base/utils/EVM.merge.cmd.pl 03.gene_predict/04.evm/evm_for_each_chr $config{EVM} > 03.gene_predict/04.evm/04.merge.sh \n";
    say EVM "parallel -j $config{threads} < 03.gene_predict/04.evm/04.merge.sh \n";
    say EVM "cat 03.gene_predict/04.evm/evm_for_each_chr/*/evm.out.gff > 03.gene_predict/04.evm/merge.out.gff  \n";
    say EVM "perl /data/00/software/EVM/EVM_V1.1.1/EVidenceModeler-1.1.1/EvmUtils/gff3_file_to_proteins.pl 03.gene_predict/04.evm/merge.out.gff $config{genome} prot > 03.gene_predict/04.evm/merge.out.gff.pep  \n";
    say EVM "perl $base/utils/gff.clean_name2spe.pl 03.gene_predict/04.evm/merge.out.gff $config{species_abbreviation} 03.gene_predict/04.evm/merge.out.gff.fix";
    say EVM "/data/00/user/user101/software/gffread/gffread 03.gene_predict/04.evm/merge.out.gff.fix -g $config{genome} -x 03.gene_predict/04.evm/merge.out.gff.fix.cds -y 03.gene_predict/04.evm/merge.out.gff.fix.pep";
    close EVM;
    
    say "!!!Step 2: Creating gene annotation cmd done. Just running sh 03.gene_predict*sh according the orders \n";
}else{
    die "wrong step number \n";
}




sub read_conf {
    my %r;
    $config=abs_path($config);
    open (TF,"$config") || die "no such file: $config\n";
    while (<TF>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        next unless $_=~/^(\S+)\s+=\s+(\S+)/;
	$_=~/^(\S+)\s+=\s+(\S+)/;
        $r{$1}=$2;
    }
    close TF;
    return %r;
}


