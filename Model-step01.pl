use Getopt::Long;
use FindBin qw($Bin);

sub usage{
	print STDERR <<USAGE;
	Version 1.0 2021-11-14 by YaoYe
	Machine learning Prediction Pipeline. 
	Use Boruta to select important variations for each trait

	Options 
		-TrainingX  <s> : Required, Train Data Variable --> X
		-TrainingY  <s> : Required, Train Data Strain Variable --> Y
USAGE
}

my ($TrainingX,$TrainingY);
GetOptions(
	"TrainingX:s"=>\$TrainingX,
	"TrainingY:s"=>\$TrainingY,
);
if(!defined($TrainingX) || !defined($TrainingY)){
        usage;
        exit;
}

my ($line,@inf,%tx,%ty,@sample);
open IN,"$TrainingX" or die "$TrainingX not open\n";
my $n=0;
while($line=<IN>){
	chomp $line;
	$tx{$n}=$line;
	$n++;
}
close IN;
open IN,"$TrainingY" or die "$TrainingY not open\n";
my $n=1;
$line=<IN>;chomp $line;@inf=split /,/,$line;
for(my $i=0;$i<=$#inf;$i++){
	push @sample,$inf[$i];
}
while($line=<IN>){
	chomp $line;
	$ty{$n}=$line;
	$n++;
}
close IN;

for(my $i=0;$i<=$#sample;$i++){
	open OA,">TrainingInputALL.$sample[$i].csv" or die "TrainingInputALL.$sample[$i].csv not open\n";
	open OB,">TrainingInputALL.$sample[$i].R" or die "TrainingInputALL.$sample[$i].R not open\n";
	print OB "library(Boruta);library(data.table)\n";
	print OB "data1=fread(\"TrainingInputALL.$sample[$i].csv\",sep=\",\")\n";
	print OB "Boruta($sample[$i]~.,data=data1)->BorutaTarget\n";
	print OB "write.table(attStats(BorutaTarget),file=\"Boruta-$sample[$i].csv\",sep=\",\")\n";
	print OB "pdf(\"Boruta-$sample[$i].pdf\")\n";
	print OB "plot(BorutaTarget)\n";
	print OB "dev.off()\n";
	close OB;
	print OA "$sample[$i],$tx{0}\n";
	for(my $j=1;$j<$n;$j++){
		@inf=split /,/,$ty{$j};
		print OA "$inf[$i],$tx{$j}\n";
	}
	close OA;
	print "Rscript TrainingInputALL.$sample[$i].R\n";
}
