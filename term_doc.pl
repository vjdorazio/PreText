##  term_doc.pl
##  Vito D'Orazio
##  Contact: vjdorazio@gmail.com
##  September 11, 2015
#
##  program to read documents delimited by ">>>>>>>>>>>>>" and "<<<<<<<<<<<<<<<<"
##  assumes tokenization of documents already happened
##  reads in "tokens.txt"
##
##  outputes a tab-separated values file of one of the following formats: 
##  LONG, which is doc_id <tab> token <tab> weight
##  WIDE, where each row is a document, each column a token, each cell the weight
##  SVM, where each row is a document, each cell contains token_number:weight
##
##  weights are normalized term frequency or tfidf
#
##  execute in unix: perl term_doc.pl 10 NTFLONG
#
#
#!/usr/local/bin/perl
my $time_1 = time();

## list of subroutines: Porter (input file porter.pm); TrimString

####################
## subroutines

sub TrimString {
  $_[0] =~ s/^\s+//; #remove leading whites
  $_[0] =~ s/\s+$//; #remove trailing spaces
  $_[0] =~ s/\t/\ /; #remove tabs in string
  $_[0] =~ s/\r/\ /; #remove carriage return in string
  $_[0] =~ s/\n/\ /; #remove newline in string
  return $_[0];
}


##################
## main NTF program ##

my $dft = $ARGV[0]; # dft number
my $format = $ARGV[1]; # output format
#my $codedSS = $ARGV[2]; # optional coded spreadsheet -- first col is docID, last col is 0/1

my $numDoc = 0;
my %docFreq = ();
my $docID = "";
my %tdNTF = (); # will be a hash with 2 keys
my $dfThresh = $dft; # the percent of the most common unique terms in corpus to keep
#my %ssHash = ();
my %outmat = ();

# a hash of format names
my @formats = split(/,/, $format);
foreach(@formats) {
  $outmat{$_} = 1;
}

open(FIN, "tokens.txt") or die "Can\'t open input file $inputFile; error $!";
open(NTFLONG,">long_ntf.tsv") or die "Can\'t open file for ntf; error $!";
if (exists($outmat{"NTFWIDE"})) {
  open(NTFWIDE,">wide_ntf.tsv") or die "Can\'t open file for ntf; error $!";
}
if (exists($outmat{"NTFSVM"})) {
  open(NTFSVM,">svm_ntf.dat") or die "Can\'t open file for ntf; error $!";
}

# establish the coded spreadsheet hash
#if($codedSS) { #because it is optional
#  open(CODED, $codedSS) or die "Can\'t open coded spreadsheet file; error $!";
#  while($observation = <CODED>) {
#    my @data = split(/\t/, $observation);
#    $ssHash{$data[0]} = &TrimString($data[$#data]); # initializing hash of docID and coded value -- 0 or 1
#  }
#}
#close(CODED);

FILE: while ($line = <FIN>) {
  $line = &TrimString($line);
  my @termArray = ();
  my %termHash = ();
  
  if ($line =~ m/Key: /) {
    $line =~ s/Key: //;
    $docID = $line;
    ++$numDoc;
  }
  
  $line =~ s/^\s+//; #remove leading whites
  if ($line =~ m/>>>>>>>>>>>>>>>>>>>>>>/) {  # story
  
    STORY: while ($line = <FIN>) {
      $line = &TrimString($line);
      if ($line =~ m/<<<<<<<<<<<<<<<<<<<<<</) {last STORY;}
      my @words = split(/\s+/, $line);
      foreach(@words) {
        $_ = lc $_; #making string lowercase
	$_ =~ s/[^\w]//g;
        $_ = &TrimString($_);
        if ($_ =~ /\d+/) {next;} # skip numbers
	if ($_ =~ /^\s*$/) {next;} # skip blanks and empties
	push(@termArray, $_);
      }        
    } # end story

      # for each term in the array, a key is established and the value is the number of times the term appears in the array
      $termHash{ $_ }++ for @termArray;

      # for each key (unique term) in termHash, docFreq + 1
      $docFreq{ $_ }++ for (keys %termHash);

      $maxKey = (sort { $termHash{$b} <=> $termHash{$a} } keys %termHash)[0];
      $maxVal = $termHash{ $maxKey };

      while (($key, $value) = each(%termHash)) {
	$tdNTF -> {$docID} -> {$key} = $value / $maxVal;
      }

      $docID = "";
  } # end if match >>>>>

} # end FILE loop

#####################################
## document frequency thresholding ##

my @keepKey = (sort { $docFreq{$b} <=> $docFreq{$a} } keys %docFreq);
my $keepNum = ($dfThresh / 100) * @keepKey;
@keepKey = @keepKey[0..$keepNum];


###############################
## print NTF long, wide, svm ##

if (exists($outmat{"NTFWIDE"})) {
  print NTFWIDE do {
      local $" = "\t";
      "doc_id\t"."@keepKey\n";
  };
}

  foreach $doc (keys %$tdNTF) {
	my @ df = ();
	push(@df, $doc);
	foreach (@keepKey) {
		if (defined ($tdNTF->{$doc}->{$_})) {
		  my $weight = sprintf("%.4g", $tdNTF->{$doc}->{$_});
		  push(@df, $weight);
		  print NTFLONG "$doc\t$_\t$weight\n";
		}
		else {
			push(@df, "0");
		}
	      }
	if(exists($outmat{"NTFWIDE"})) {
	  print NTFWIDE do {
	    local $" = "\t";
	    "@df\n";
	  };
	}
      } #end foreach outter loop

if (exists($outmat{"NTFSVM"})) {

  foreach $doc (keys %$tdNTF) {
    my @svmdf = (); # array that will hold the elements for SVM light format
    my $i1 = 1; # ugly, but it'll do
    foreach (@keepKey) {
      if (exists ($tdNTF->{$doc}->{$_})) {
	my $weight = sprintf("%.4g", $tdNTF->{$doc}->{$_});
        push(@svmdf, "$i1:".$weight); # SVM light format
      }
      ++$i1;
    }

    push(@svmdf, " # ".$doc."\n"); # puts hash doc ID at the end of the array
    my $label = 0;
#    if (exists ($ssHash{$doc})) {
#      if($ssHash{$doc} == 1) {$label = 1;}
#      if($ssHash{$doc} != 1) {$label = -1;} 
#    }
    unshift(@svmdf, $label); # puts -1 or 1 if coded, 0 if not coded
    print NTFSVM do {
       local $" = "\t";
       "@svmdf";
     };
  
  }
} 


close(FIN);
close(NTFLONG);
if (exists($outmat{"NTFWIDE"})) { close(NTFWIDE); }
if (exists($outmat{"NTFSVM"})) { close(NTFSVM); }

## if this evaluates to true, program exits
## otherwise, tfidf will be calculated and printed in at least one of these formats
if (!exists($outmat{"TFIDFLONG"}) && !exists($outmat{"TFIDFWIDE"}) && !exists($outmat{"TFIDFSVM"})) {
  my $time_2 = time();
  my $diff = $time_2 - $time_1;
  print "\nFinished in $diff seconds.\n";
  exit;
}


#########################################
## open files and establish tfidf hash ##

open (NTFIN, "long_ntf.tsv") or die "Can\'t open ntf file that was just written... odd...; error $!";

if (exists($outmat{"TFIDFLONG"})) {
  open(TFIDFLONG,">long_tfidf.tsv") or die "Can\'t open file for tfidf; error $!";
}

if (exists($outmat{"TFIDFWIDE"})) {
  open(TFIDFWIDE,">wide_tfidf.tsv") or die "Can\'t open file for tfidf; error $!";
}

if (exists($outmat{"TFIDFSVM"})) {
  open(TFIDFSVM, ">svm_tfidf.dat") or die "Can\'t open file for tfidf SVM; error $!";
}

my %tdTFIDF = (); # will be a hash with 2 keys and value is tfidf

while($dataLine = <NTFIN>) {
	if($dataLine =~ m/(\S+)\t(\S+)\t(\S+)/) {
		$tdTFIDF -> {$1} -> {$2} = $3 * (log($numDoc /(1+($docFreq{ $2 }))));
	}
} # end while

#######################################
## Check and print to desired format ##

## TFIDFLONG
if(exists($outmat{"TFIDFLONG"})) {
foreach $doc (keys %$tdTFIDF) {
  my @df = ();
  my $i1 = 1; # ugly, but it'll do
  push(@df, $doc);
  foreach (@keepKey) {
    if (defined ($tdTFIDF->{$doc}->{$_})) {
      my $weight = sprintf("%.4g", $tdTFIDF->{$doc}->{$_});
      push(@df, $weight);
      print TFIDFLONG "$doc\t$_\t$weight\n";
    }
    else {
	push(@df, "0");
    }
    ++$i1;
  }  
}
} # end the if for formatting

## TFIDFWIDE
if(exists($outmat{"TFIDFWIDE"})) {

  print TFIDFWIDE do {
      local $" = "\t";
      "doc_id\t"."@keepKey\n";
  };

foreach $doc (keys %$tdTFIDF) {
  my @df = ();
  my $i1 = 1; # ugly, but it'll do
  push(@df, $doc);
  foreach (@keepKey) {
    if (defined ($tdTFIDF->{$doc}->{$_})) {
      my $weight = sprintf("%.4g", $tdTFIDF->{$doc}->{$_});
      push(@df, $weight);
    }
    else {
	push(@df, "0");
    }
    ++$i1;
  }
  
  print TFIDFWIDE do {
  local $" = "\t";
  "@df\n";
  };
}
} # end the if for formatting

## TFIDFSVM
if(exists($outmat{"TFIDFSVM"})) {
foreach $doc (keys %$tdTFIDF) {
  my @svmdf = (); # array that will hold the elements for SVM light format
  my $i1 = 1; # ugly, but it'll do
  foreach (@keepKey) {
    if (defined ($tdTFIDF->{$doc}->{$_})) {
      my $weight = sprintf("%.4g", $tdTFIDF->{$doc}->{$_});
      push(@svmdf, "$i1:".$weight); # SVM light format
    }
    ++$i1;
  }

  push(@svmdf, " # ".$doc."\n"); # puts hash doc ID at the end of the array
  my $label = 0;
#  if (exists ($ssHash{$doc})) {
#    if($ssHash{$doc} == 1) {$label = 1;}
#    if($ssHash{$doc} != 1) {$label = -1;} 
#  }
  unshift(@svmdf, $label); # puts -1 or 1 if coded, 0 if not coded
  print TFIDFSVM do {
       local $" = "\t";
       "@svmdf";
  };
  
}
} # end the if for formatting

close(NTFIN);
if(exists($outmat{"TFIDFLONG"})) { close(TFIDFLONG); }
if(exists($outmat{"TFIDFWIDE"})) { close(TFIDFWIDE); }
if(exists($outmat{"TFIDFSVM"})) { close(TFIDFSVM); }

my $time_2 = time();
my $diff = $time_2 - $time_1;
print "\nFinished in $diff seconds.\n";
exit;
