die "perl $0 Model-performance-list.txt Model-Detail.csv\n" if(@ARGV!=2);
my ($line,@inf);

open IN, "$ARGV[0]" or die "can not open file: $ARGV[0]\n";
open OA, ">$ARGV[1]" or die "can not open file: $ARGV[1]\n";
print OA "Trait,Methods,Parameter,Value\n";
while($line=<IN>){
	chomp $line;
	@inf=split /\t/,$line;
	my $id=$inf[0];
	open IA, "$inf[1]" or print "$inf[1] not open\n";
	<IA>;
	while($line=<IA>){
		print OA "$id,$line"; 
	}
	close IA;
}
close IN;
close OA;
