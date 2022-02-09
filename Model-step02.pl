use Getopt::Long;
use FindBin qw($Bin);

sub usage{
	print STDERR <<USAGE;
	Version 1.0 2021-11-1 by YaoYe
	Machine learning Prediction Pipeline. 
	Ignore the importance for each variable

	Options 
		-TrainingX  <s> : Required, Train Data Variable --> X
		-TrainingY  <s> : Required, Train Data Strain Variable --> Y
		-RealdataX  <s> : Required, Real Data Strain Variable --> Y
		-RealdataY  <s> : Required, Real Data Strain Variable --> Y
		-out        <s> : output dir, default: pwd
USAGE
}

my ($TrainingX,$TrainingY,$RealdataX,$RealdataY,$out);
GetOptions(
	"TrainingX:s"=>\$TrainingX,
	"TrainingY:s"=>\$TrainingY,
	"RealdataX:s"=>\$RealdataX,
	"RealdataY:s"=>\$RealdataY,
	"out:s"=>\$out,
);
#$out||=`pwd`; chomp $out;
if(!defined($TrainingX) || !defined($TrainingY)|| !defined($RealdataX)|| !defined($RealdataY)){
        usage;
        exit;
}

my ($line,@inf,%tx,%ty,@sample);
open IN,"$TrainingX" or print "$TrainingX not open\n";
my $n=0;
while($line=<IN>){
	chomp $line;
	$tx{$n}=$line;
	$n++;
}
close IN;
open IN,"$TrainingY" or print  "$TrainingY not open\n";
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
	my %hit=();
	open IN,"Boruta-$sample[$i].csv" or print "Boruta-$sample[$i].csv not open\n";
	open OA,">TrainingInput.$sample[$i].csv" or print "TrainingInput.$sample[$i].csv not open\n";
	print OA "$sample[$i]";
	<IN>;
	my $h=0;
	while($line=<IN>){
		chomp $line;
		$line=~s/['"]//g;
		@inf=split /,/,$line;
		$h++;
		if($inf[6] eq "Confirmed"){
			$hit{$h}=1;
			print OA ",$inf[0]";
		}
	}
	close IN;
	print OA "\n";
	
	for(my $j=1;$j<$n;$j++){
		@inf=split /,/,$ty{$j};
		print OA "$inf[$i]";
		@ele=split /,/,$tx{$j};
		for(my $m=0;$m<=$#ele;$m++){
			print OA ",$ele[$m]" if(defined $hit{$m+1});
		}
		print OA "\n";
	}
	close OA;
}

my (%rx,%ry,@sample2);
open IN,"$RealdataX" or die "$RealdataX not open\n";
my $n=0;
while($line=<IN>){
	chomp $line;
	$rx{$n}=$line;
	$n++;
}
close IN;
open IN,"$RealdataY" or die "$RealdataY not open\n";
my $n=1;
$line=<IN>;chomp $line;@inf=split /,/,$line;
for(my $i=0;$i<=$#inf;$i++){
	push @sample2,$inf[$i];
}
while($line=<IN>){
	chomp $line;
	$ry{$n}=$line;
	$n++;
}
close IN;

for(my $i=0;$i<=$#sample2;$i++){
	my %hit=();
	open IN,"Boruta-$sample2[$i].csv" or print "Boruta-$sample2[$i].csv not open\n";
	open OA,">RealInput.$sample2[$i].csv" or print "RealInput.$sample2[$i].csv not open\n";
	print OA "$sample2[$i]";
	<IN>;
	my $h=0;
	while($line=<IN>){
		chomp $line;
		$line=~s/['"]//g;
		@inf=split /,/,$line;
		$h++;
		if($inf[6] eq "Confirmed"){
			$hit{$h}=1;
			print OA ",$inf[0]";
		}
	}
	close IN;
	print OA "\n";
	
	for(my $j=1;$j<$n;$j++){
		@inf=split /,/,$ry{$j};
		print OA "$inf[$i]";
		@ele=split /,/,$rx{$j};
		for(my $m=0;$m<=$#ele;$m++){
			print OA ",$ele[$m]" if(defined $hit{$m+1});
		}
		print OA "\n";
	}
	close OA;
}

#Rscripts
open OS2, ">Model-performance-list.txt" or die "Model-performance-list.txt not open";
for(my $i=0;$i<=$#sample2;$i++){
	open OA,">Rscripts.$sample2[$i].R" or die "Rscripts.$sample2[$i].R not open\n";
	print OA "library(impute);library(data.table);library(ggplot2);library(ggpmisc)\n";
	print OA "data1=fread(\"TrainingInput.$sample2[$i].csv\",sep=\",\")\n";
	print OA "needpredict=fread(\"RealInput.$sample2[$i].csv\",sep=\",\")\n";
	print OA "realvalue=needpredict\$$sample2[$i]\n";
	print OA "realvalue=as.matrix(realvalue)\n";
	print OA "w <- na.omit(data1) \n";
	print OA "n=nrow(w);Z=5; zz1=1:n  \n";
	print OA "zz2 <- rep(1:Z,ceiling(n/Z))[1:n]\n";
	print OA "set.seed(100);zz2 <- sample(zz2,n) \n";
	print OA "library(rpart);library(rpart.plot)\n";
	print OA "a <- rpart($sample2[$i]~.,w)\n";
	print OA "rpart_predict=predict(a,needpredict[,])\n";
	print OA "rpart_predict_r2=as.numeric(cor(rpart_predict,realvalue)^2)\n";
	print OA "rpart_predict_RMSE=sqrt(mean((rpart_predict-realvalue)^2))\n\n";
	print OA "NMSE <- rep(0,Z);NMSE0=NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m=zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a=rpart($sample2[$i]~.,w[-m,]) \n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(rpart_MNMSE0 <- mean(NMSE0));(rpart_MNMSE <- mean(NMSE))\n";
	print OA "(rpart_r2 <- mean(R2));(rpart_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(rpart_predict,realvalue)\n";
	print OA "rpart_figure=ggplot(df, aes(rpart_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"rpart_predict\") + ylab(\"realvalue\")+ggtitle(\"Rpart\")\n";

	print OA "library(randomForest)\n";
	print OA "set.seed(10)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- randomForest($sample2[$i]~.,data=w,mtry=3,importance=TRUE,importanceSD=T)\n";
	print OA "RF_predict=predict(a,needpredict[,])\n";
	print OA "RF_predict_r2=as.numeric(cor(RF_predict,realvalue)^2)\n";
	print OA "RF_predict_RMSE=sqrt(mean((RF_predict-realvalue)^2))\n";
	print OA "set.seed(101)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- randomForest($sample2[$i]~.,data=w[-m,],mtry=3,importance=TRUE)\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(RF_MNMSE0 <- mean(NMSE0));(RF_MNMSE <- mean(NMSE));\n";
	print OA "(RF_r2 <- mean(R2));(RF_RMSE <- mean(RMSE))\n";
	print OA "df <- data.frame(RF_predict,realvalue)\n";
	print OA "rf_figure=ggplot(df, aes(RF_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"RF_predict\") + ylab(\"realvalue\")+ggtitle(\"RandomForest\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"svm\")\n";
	print OA "SVM_predict=predict(a,needpredict[,])\n";
	print OA "SVM_predict_r2=as.numeric(cor(SVM_predict,realvalue)^2)\n";
	print OA "SVM_predict_RMSE=sqrt(mean((SVM_predict-realvalue)^2))\n";
	print OA "set.seed(444)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[-m,],model=\"svm\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(SVM_MNMSE0 <- mean(NMSE0));(SVM_MNMSE <- mean(NMSE));\n";
	print OA "(SVM_r2 <- mean(R2));(SVM_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(SVM_predict,realvalue)\n";
	print OA "svm_figure=ggplot(df, aes(SVM_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"SVM_predict\") + ylab(\"realvalue\")+ggtitle(\"SVM\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[,],model=\"mlpe\")\n";
	print OA "MLPE_predict=predict(a,needpredict[,])\n";
	print OA "MLPE_predict_r2=as.numeric(cor(MLPE_predict,realvalue)^2)\n";
	print OA "MLPE_predict_RMSE=sqrt(mean((MLPE_predict-realvalue)^2))\n";
	print OA "set.seed(444)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[-m,],model=\"mlpe\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(MLPE_MNMSE0 <- mean(NMSE0));(MLPE_MNMSE <- mean(NMSE));\n";
	print OA "(MLPE_r2 <- mean(R2));(MLPE_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(MLPE_predict,realvalue)\n";
	print OA "mlpe_figure=ggplot(df, aes(MLPE_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"MLPE_predict\") + ylab(\"realvalue\")+ggtitle(\"MLPE\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"cubist\")\n";
	print OA "CUBIST_predict=predict(a,needpredict[,])\n";
	print OA "CUBIST_predict_r2=as.numeric(cor(CUBIST_predict,realvalue)^2)\n";
	print OA "CUBIST_predict_RMSE=sqrt(mean((CUBIST_predict-realvalue)^2))\n";
	print OA "set.seed(444)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[-m,],model=\"cubist\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(CUBIST_MNMSE0 <- mean(NMSE0));(CUBIST_MNMSE <- mean(NMSE));\n";
	print OA "(CUBIST_r2 <- mean(R2));(CUBIST_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(CUBIST_predict,realvalue)\n";
	print OA "cubist_figure=ggplot(df, aes(CUBIST_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"CUBIST_predict\") + ylab(\"realvalue\")+ggtitle(\"CUBIST\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"cv.glmnet\")\n";
	print OA "GLM_predict=predict(a,needpredict[,])\n";
	print OA "GLM_predict_r2=as.numeric(cor(GLM_predict,realvalue)^2)\n";
	print OA "GLM_predict_RMSE=sqrt(mean((GLM_predict-realvalue)^2))\n";
	print OA "set.seed(444)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[-m,],model=\"cv.glmnet\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(GLM_MNMSE0 <- mean(NMSE0));(GLM_MNMSE <- mean(NMSE));\n";
	print OA "(GLM_r2 <- mean(R2));(GLM_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(GLM_predict,realvalue)\n";
	print OA "glm_figure=ggplot(df, aes(GLM_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"GLM_predict\") + ylab(\"realvalue\")+ggtitle(\"GLM\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"kknn\")\n";
	print OA "kknn_predict=predict(a,needpredict[,])\n";
	print OA "kknn_predict_r2=as.numeric(cor(kknn_predict,realvalue)^2)\n";
	print OA "kknn_predict_RMSE=sqrt(mean((kknn_predict-realvalue)^2))\n";
	print OA "set.seed(444)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[-m,],model=\"kknn\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(kknn_MNMSE0 <- mean(NMSE0));(kknn_MNMSE <- mean(NMSE));\n";
	print OA "(kknn_r2 <- mean(R2));(kknn_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(kknn_predict,realvalue)\n";
	print OA "kknn_figure=ggplot(df, aes(kknn_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"kknn_predict\") + ylab(\"realvalue\")+ggtitle(\"KKNN\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"mars\")\n";
	print OA "mars_predict=predict(a,needpredict[,])\n";
	print OA "mars_predict_r2=as.numeric(cor(mars_predict,realvalue)^2)\n";
	print OA "mars_predict_RMSE=sqrt(mean((mars_predict-realvalue)^2))\n";
	print OA "set.seed(444)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,data=w[-m,],model=\"mars\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))}\n";
	print OA "(mars_MNMSE0 <- mean(NMSE0));(mars_MNMSE <- mean(NMSE));\n";
	print OA "(mars_r2 <- mean(R2));(mars_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(mars_predict,realvalue)\n";
	print OA "mars_figure=ggplot(df, aes(mars_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"mars_predict\") + ylab(\"realvalue\")+ggtitle(\"MARS\")\n";
	
	print OA "library(rminer)\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"plsr\")\n";
	print OA "plsr_predict=predict(a,needpredict[,])\n";
	print OA "plsr_predict_r2=as.numeric(cor(plsr_predict,realvalue)^2)\n";
	print OA "plsr_predict_RMSE=sqrt(mean((plsr_predict-realvalue)^2))\n";
	print OA "set.seed(4)\n";
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- fit($sample2[$i]~.,w,model=\"plsr\")\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))\n";
	print OA "}\n";
	print OA "(plsr_MNMSE0 <- mean(NMSE0));(plsr_MNMSE <- mean(NMSE));\n";
	print OA "(plsr_r2 <- mean(R2));(plsr_RMSE <- mean(RMSE))\n";
	print OA "\n";
	print OA "df <- data.frame(plsr_predict,realvalue)\n";
	print OA "plsr_figure=ggplot(df, aes(plsr_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"plsr_predict\") + ylab(\"realvalue\")+ggtitle(\"PLSR\")\n";
	
	print OA "NMSE <- rep(0,Z);NMSE0 <- NMSE;R2=NMSE;RMSE=NMSE;\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- lm($sample2[$i]~.,data=w)\n";
	print OA "LM_predict=predict(a,needpredict[,])\n";
	print OA "LM_predict_r2=as.numeric(cor(LM_predict,realvalue)^2)\n";
	print OA "LM_predict_RMSE=sqrt(mean((LM_predict-realvalue)^2))\n";
	print OA "for(i in 1:Z){\n";
	print OA "m <- zz1[zz2==i]\n";
	print OA "w=as.data.frame(w)\n";
	print OA "a <- lm($sample2[$i]~.,data=w[-m,])\n";
	print OA "y0 <- predict(a,w[-m,])\n";
	print OA "y1 <- predict(a,w[m,])\n";
	print OA "w=as.matrix(w)\n";
	print OA "NMSE0[i] <- mean((w[-m,1]-y0)^2)/mean((w[-m,1]-mean(w[-m,1]))^2)\n";
	print OA "NMSE[i] <- mean((w[m,1]-y1)^2)/mean((w[m,1]-mean(w[m,1]))^2)\n";
	print OA "R2[i]=cor(y1,w[m,1])^2\n";
	print OA "RMSE[i]=sqrt(mean((w[m,1]-y1)^2))\n";
	print OA "}\n";
	print OA "(LM_MNMSE0 <- mean(NMSE0));(LM_MNMSE <- mean(NMSE));\n";
	print OA "(LM_r2 <- mean(R2));(LM_RMSE <- mean(RMSE))\n\n";
	print OA "df <- data.frame(LM_predict,realvalue)\n";
	print OA "lm_figure=ggplot(df, aes(LM_predict, realvalue))+ geom_point(color = \"grey50\",size = 3)+  stat_smooth(color = \"skyblue\", formula = y ~ x,fill = \"skyblue\", method = \"lm\")+ theme(panel.grid.major =element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),axis.line = element_line(colour = \"black\"))+ stat_poly_eq(aes(label = paste(..eq.label.., ..adj.rr.label..,..p.value.label.., sep = \"~~~~\")),formula = y ~ x,  parse = TRUE, size = 3)+xlab(\"LM_predict\") + ylab(\"realvalue\")+ggtitle(\"Linear\")\n";
	
	print OA "Methods <- c(\'DTree\',\'RF\',\'SVM\',\'Linear\',\'MLPE\',\"CUBIST\",\"GLM\",\"KKNN\",\"plsr\",\"mars\")\n";
	print OA "MNMSE <- c(rpart_MNMSE,RF_MNMSE,SVM_MNMSE,LM_MNMSE,MLPE_MNMSE,CUBIST_MNMSE,GLM_MNMSE,kknn_MNMSE,plsr_MNMSE,mars_MNMSE)\n";
	print OA "R2 <- c(rpart_r2,RF_r2,SVM_r2,LM_r2,MLPE_r2,CUBIST_r2,GLM_r2,kknn_r2,plsr_r2,mars_r2)\n";
	print OA "RMSE <- c(rpart_RMSE,RF_RMSE,SVM_RMSE,LM_RMSE,MLPE_RMSE,CUBIST_RMSE,GLM_RMSE,kknn_RMSE,plsr_RMSE,mars_RMSE)\n";
	print OA "Real_R2 <- c(rpart_predict_r2,RF_predict_r2,SVM_predict_r2,LM_predict_r2,MLPE_predict_r2,CUBIST_predict_r2,GLM_predict_r2,kknn_predict_r2,plsr_predict_r2,mars_predict_r2)\n";
	print OA "Real_RMSE <- c(rpart_predict_RMSE,RF_predict_RMSE,SVM_predict_RMSE,LM_predict_RMSE,MLPE_predict_RMSE,CUBIST_predict_RMSE,GLM_predict_RMSE,kknn_predict_RMSE,plsr_predict_RMSE,mars_predict_RMSE)\n";
	print OA "df <- data.frame(Methods,MNMSE,R2,RMSE,Real_R2,Real_RMSE)\n";
	print OA "df[is.na(df)]=0\n";
	print OA "write.table(df,file=\"$sample2[$i].model-performance.csv\",sep=\",\",row.names = F)\n";
	print OA "library(reshape2)\n";
	print OA "mydata<-read.csv(\"$sample2[$i].model-performance.csv\",sep=\",\",na.strings=\"NA\",stringsAsFactors=FALSE)\n";
	print OA "mydata<-melt(mydata,id.vars=\'Methods\')\n";
	print OA "write.table(mydata,sep=\",\",file=\"$sample2[$i].model-performance-list.csv\",row.names = F)\n";
	print OA "library(ggplot2)\n";
	print OA "library(gridExtra)\n";
	print OA "inputdata=mydata[mydata\$variable==\"MNMSE\",]\n";
	print OA "MNMSE=ggplot(data = inputdata,aes(x = Methods, y = value,col=Methods)) + \n";
	print OA "geom_bar(stat=\'identity\', aes(fill=Methods), width=.5) + ylab(\"MNMSE\") + \n";
	print OA "ggtitle(\"Model MNMSE\") + \n";
	print OA "theme(plot.title = element_text(lineheight=.8, face=\"bold\",hjust = 0.5)) + \n";
	print OA "theme(legend.position=\"none\")\n";
	print OA "inputdata=mydata[mydata\$variable==\"R2\",]\n";
	print OA "R2=ggplot(data = inputdata,aes(x = Methods, y = value,col=Methods)) + \n";
	print OA "geom_bar(stat=\'identity\', aes(fill=Methods), width=.5) + ylab(\"R2\") + \n";
	print OA "ggtitle(\"Model R2\") + \n";
	print OA "theme(plot.title = element_text(lineheight=.8, face=\"bold\",hjust = 0.5)) + \n";
	print OA "theme(legend.position=\"none\")\n";
	print OA "inputdata=mydata[mydata\$variable==\"RMSE\",]\n";
	print OA "RMSE=ggplot(data = inputdata,aes(x = Methods, y = value,col=Methods)) + \n";
	print OA "geom_bar(stat=\'identity\', aes(fill=Methods), width=.5) + ylab(\"RMSE\") + \n";
	print OA "ggtitle(\"RealData Predict RMSE\") + \n";
	print OA "theme(plot.title = element_text(lineheight=.8, face=\"bold\",hjust = 0.5)) + \n";
	print OA "theme(legend.position=\"none\")\n";
	print OA "inputdata=mydata[mydata\$variable==\"Real_R2\",]\n";
	print OA "Real_R2=ggplot(data = inputdata,aes(x = Methods, y = value,col=Methods)) + \n";
	print OA "geom_bar(stat=\'identity\', aes(fill=Methods), width=.5) + ylab(\"Real_R2\") + \n";
	print OA "ggtitle(\"RealData Predict R2\") + \n";
	print OA "theme(plot.title = element_text(lineheight=.8, face=\"bold\",hjust = 0.5)) + \n";
	print OA "theme(legend.position=\"none\")\n";
	print OA "pdf(\"$sample2[$i].Evaluation.pdf\",width=12,height=8)\n";
	print OA "grid.arrange(MNMSE,R2,RMSE,Real_R2,ncol=2,nrow=2)\n";
	print OA "dev.off()\n";
	print OA "pdf(\"$sample2[$i].Predict.pdf\",width=28,height=8)\n";
	print OA "grid.arrange(rpart_figure,rf_figure,svm_figure,mlpe_figure,cubist_figure,glm_figure,kknn_figure,mars_figure,plsr_figure,lm_figure,ncol=5,nrow=2)\n";
	print OA "dev.off()\n";
	
	print OS2 "$sample2[$i]\t$sample2[$i].model-performance-list.csv\n";
	print "Rscript Rscripts.$sample2[$i].R \n";
	close OA;
}
close OS2;
