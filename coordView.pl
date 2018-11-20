#! perl -w
#  Written by: Chen Dong
#  Date time : 2018-11-13 15:59
#  思路：做两次文本比对得出结果
#  2018-11-19 用了Tie::File这个模块读取大文本内容
#  2018-11-19 做个进度条，针对大文件，速度慢
###################################

use strict;
use warnings;
use Win32::GUI();
use File::Copy;
use Tie::File;
use File::Basename;
use Win32::GUI qw(MB_OK MB_ICONINFORMATION MB_ICONQUESTION MB_YESNOCANCEL MB_YESNO);


MAIN:;
my $font = Win32::GUI::Font->new(-name => "Franklin Gothic Medium",-bold => 0, -size => 12,);
my $bg = [229,229,229];
my $fg = [0,0,255];
my $scale_x = 0.1;
my $scale_y = 0.05;
my $outFiles;
####　构建Win32窗口
my $Window = new Win32::GUI::Window (
	-name  => "Window",
	-title => "锣带坐标修复(V3.0)",
	-pos   => [150, 150],
	-size  => [330, 250],
	-dialogui => 1,
);

# 加载文件事件按钮
$Window->AddButton(
	      -name         => 'read',
	      -text         => "读取",
		  -size         => [60 ,30],
		  -pos          => [5,5],
		  -default      => 1,
		  -tabstop		=> 1,
		  -group	    => 1,
);

$Window->AddTextfield (
		-name => 'rou',
		-pos  => [70,5],
		-size => [210, 25],
		-align => 'left',
		-number => 0,
		-pushstyle => 0,
);
 
$Window->AddGroupbox(   
		-name	=>	"swap",
		-title  =>	"数值输入框",
		-font   => $font,
		-pos    =>  [10,50],
		-size   =>  [232,63],
);

$Window->AddLabel(
		-name   =>  "scale11",
		-background   => $bg,
		-font 	=> $font,
	#	-text   => "X:", 
		-left   => $Window->swap->Left + 15,
		-top    => $Window->swap->Top  + 23,
);

$Window->AddTextfield (
		-name 	=>  "vauX",
		-font   =>  $font,
		-foreground => $fg,
		-text   =>  "$scale_x",
		-height =>  30,
		-width  =>  85,
		-left   =>  $Window->scale11->Left + $Window->scale11->Width,
		-top    =>  $Window->scale11->Top - 4,
);

$Window->AddLabel(
		-name		=>	"scale22",
		-background =>	$bg,
		-font 		=>	$font,
	#	-text 		=>  "Y:",
		-left		=>  $Window->vauX->Left + $Window->vauX->Width + 2,
		-top		=>	$Window->swap->Top + 23,
);

$Window->AddTextfield (
		-name		=>	"vauY",
		-font 		=>	$font,
		-foreground =>	$fg,
		-text 		=>	"$scale_y",
		-height		=>  30,
		-width 		=>  85,
		-left 		=> 	$Window->scale22->Left + $Window->scale22->Width,
		-top 		=>	$Window->scale22->Top - 4,
);

# $Window->AddButton (
		# -name	 => "swapBtn",
		# -text	 =>	"<=>",
		# -default =>	1,
		# -ok		 => 0,
		# -font 	 => $font,
		# -width	 => 70,
		# -height	 => 25,
		# -left 	 => $Window->swap->Left + 90,
		# -top	 => $Window->swap->Top - 6,
# );

$Window->AddButton (
		-name		=> "dest",
		-text 	 	=> "输出路径:",
		-default 	=> 1,
		-pos		=> [5, 120],
		-size 		=> [70,30]
);

$Window->AddTextfield (
		-name => 'outFile',
		-pos  => [80,123],
		-size => [200, 25],
		-align => 'left',
		-number => 0,
		-pushstyle => 0,
);

$Window->AddButton (
		-name		=> "outputBtn",
		-text 	 	=> "执行",
		-default 	=> 1,
		-pos		=> [200, 150],
		-size 		=> [60,60]
);

my $Progress_bars = $Window->AddProgressBar (
							-name  => "uploadbut",
							-text  => "Uplaod",
							-smooth => 1,
							-pos   => [50,180],
							-size  => [120,20],
							-background => [190,190,190],
							-foreground => [],
							-tabstop => 1,
);
$Window->Show();
Win32::GUI::Dialog();
exit(0);

######窗口构建完成






sub Window_Terminate {
    return -1;   # Stop message loop and finish program
}


##  交换文本框的数据
# sub swapBtn_Click {
	# my $val_x = $Window->vauX->Text();
	# $val_x =~ s/\.+/342895789345/;
	# $val_x =~ s/\W//;
	# $val_x =~ s/ //;
	# $val_x =~ s/\D//;
	# $val_x =~ s/342895789345/\./;
	# $Window->vauX->Text($val_x);
	# $val_x = $Window->vauX->Text();
	
	# my $val_y = $Window->vauY->Text();
	# $val_y =~ s/\.+/342895789345/;
	# $val_y =~ s/\W//;
	# $val_y =~ s/ //;
	# $val_y =~ s/\D//;
	# $val_y =~ s/342895789345/\./;
	# $Window->vauY->Text($val_y);
	# $val_y = $Window->vauY->Text();
	
	# $Window->vauX->Text($val_y);
	# $Window->vauY->Text($val_x);
# }

#####

sub read_Click {
	my $file = Win32::GUI::GetOpenFileName(
			 -owner => $Window,
			 -title => "Open a file",
			 -filter => [
				'rout file (*.*)' => '*.*',
				'All files' => '*.*',
			 ],
			 -directory => "d:\\",
	);
	$Window->rou->Text($file);	# 得到文本路径	 
}



##  主要算法 (NxM NxN)消耗时间
sub outputBtn_Click {	
	
	my $input_file = $Window->rou->Text();
	
	my $preDir = "c:\\tmp\\";
	my $tmpFile = fileparse($input_file);
	my $output_file = "$preDir"."$tmpFile".'.GXX';
	my $out_file    = "$preDir"."$tmpFile".'.OUT';
	my $result_file = "$preDir"."$tmpFile".'.OK';
	my $dos_file    = "$preDir"."$tmpFile".'.DOS';
	
	my $getX = $Window->vauX->Text();   #相邻两行"x"坐标值,相差是否小于等于这个范围，但不能为0
	my $getY = $Window->vauY->Text();   #相邻两行"y"坐标值,相差是否小于等于这个范围，但不能为0
	my ($x1, $y1, $x2, $y2, @array);
	
	my $outFiles = $Window->outFile->Text();
	if ($outFiles eq '') {
		my $statusBtn	= $Window->MessageBox('输出路径请添写', "提示窗口", MB_ICONQUESTION | MB_YESNO);
	  goto MAIN;
	}
			
	open(IN, "<$input_file")   or die "Can not open file $input_file: $!";	
	open(OUT, ">$output_file") or die "\nError trying to open the fiel $output_file: $!";	
	open(DOS, ">$dos_file") or die "\nError trying to open the fiel$dos_file: $!";	
	while (<IN>) {    ## 先过滤出G开头坐标到指定文件
		chomp($_);
		print DOS "$_\n";    # genesis输出来的是linux[\r]格式，现转化为Window格式[\r\n]
		next if($_ !~ /^(G00|G01|G02|G03)/i);
		print OUT "$_\n";
	}
	close(DOS);
	close(OUT);
	close(IN);
	
	open(OUTFH, ">$out_file") or die "\nError trying to open the fiel $out_file: $!";
	tie @array, 'Tie::File', $output_file or die "Can not open file $output_file: $!";
	for (my $i = 0; $i < $#array; $i++){
		 if ( $array[$i] =~ /^(G00|G01|G02|G03)X(\d+.*\d)Y(\d+.*\d)[A-Z](\d+.*\d)/) { 
			  ($x1, $y1) = ($2, $3);
		 } elsif ($array[$i] =~ /^(G00|G01|G02|G03)X(\d+.*\d)Y(\d+.*\d)/){
			  ($x1, $y1) = ($2, $3);
		 }
		 
		  if ( $array[$i+1] =~ /^(G00|G01|G02|G03)X(\d+.*\d)Y(\d+.*\d)[A-Z](\d+.*\d)/) { 
			  ($x2, $y2) = ($2, $3);
		 } elsif ($array[$i+1] =~ /^(G00|G01|G02|G03)X(\d+.*\d)Y(\d+.*\d)/){
			  ($x2, $y2) = ($2, $3);
		 }
				my $tmp_x = $x1 - $x2;   							#相邻两行"x"坐标值 
				$tmp_x = sprintf "%.3f", $tmp_x;  					#只保留三位小数				
					if ($tmp_x < 0) {   							#这个值一定要为正的数，才能做出正确判断
						$tmp_x = -$tmp_x; 
					}	
				
				my $tmp_y = $y1 - $y2;  
				$tmp_y = sprintf "%.3f", $tmp_y;
					if ($tmp_y < 0) {
						$tmp_y = -$tmp_y;
					}
	
				if ( (($tmp_x <= $getX) && ($tmp_y <= $getY)) || (($tmp_x == 0) && ($tmp_y <= $getY)) || (($tmp_x <= $getX) && ($tmp_y == 0)) ) {
						print OUTFH "$array[$i+1]\n";
				} elsif ( (($tmp_y <= $getX) && ($tmp_x <= $getY)) || (($tmp_y == 0) && ($tmp_x <= $getY)) || (($tmp_y <= $getX) && ($tmp_x == 0)) ) {
						print OUTFH "$array[$i+1]\n";
				}
		 
	}
	close(OUTFH);
	untie @array;
	
	
	my (@orgFile, @resFile, $flags);
	tie @orgFile, 'Tie::File', $dos_file or die "Can not open file $output_file: $!";    #要注意是否是Linux下的文本格式 
	tie @resFile, 'Tie::File', $out_file   or die "\nERROR tyring to open the file $out_file  for writing: $!";
	open(FH, ">$result_file") or die "\nError trying to open the file $result_file: $!";	
	$Progress_bars->SetRange(0,$#orgFile);
	Win32::GUI::DoEvents();
	foreach my $org(@orgFile) {
		$Progress_bars->SetStep(1);
		$flags = 1;
		foreach my $res(@resFile) {
			if($org eq $res) {
				$flags = 0;
				last;
			}
		}
		if ($flags == 1) {
			print FH "$org\n";
		}
		# if (grep($_ ne $org, @resFile) > 0) {
			# print FH "$org\n";
		# }
		$Progress_bars->StepIt();
	}				
	close(FH);	
	
	 
	untie(@orgFile);
	untie(@resFile);
	
	copy($result_file, $outFiles);

	unlink "$output_file", "$result_file", "$dos_file", "$out_file";
	$Window->MessageBox('脚本运行完成', "提示窗口",0|0x0030);
}


sub dest_Click {
	my $inFile = $Window->rou->Text();
	my $fileName = fileparse($inFile);
	my $file = Win32::GUI::GetSaveFileName(
			 -owner => $Window,
			 -file => $fileName,
			 -title => "输出路径",
			 -directory => "d:\\",
			 -overwriteprompt => 1,
	);
	$Window->outFile->Text($file);	# 得到文本路径	
}	

