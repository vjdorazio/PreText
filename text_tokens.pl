##  text_tokens.pl
##  Vito D'Orazio
##  Contact: vjdorazio@gmail.com
##  September 11, 2015



#!/usr/local/bin/perl
use strict;
no strict 'refs';  ## this is included so that I can call the stemmer function with a variable name
## a cleaner alternative is to use a dispatcher hash of subroutines, but this works
use warnings;
my $time_1 = time();



## Global variables
my $rmact = $ARGV[0]; # Schrodt's 'CountryCodes' file or NO
my $stopsFile = $ARGV[1];  # stop word file
my $stemFile = $ARGV[2]; # stemmer
my $stemFunc = "";
my $line = ""; # one line of text from the doc at a time
my $mdata = ""; # the metadata for each story
my $text = ""; # the text of the story
my $ssCount = "0";

my @ssOut;

my %stopHash; # hash for storing stopwords
my %natref; # hash that stores the many names for states and their country codes


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

sub PrepText {
  
  my @terms;
  my @termArray;
  my $body = $_[0];
  my %ref = %{$_[1]}; # dereferences the hash
  my %catches = ();

  if(%ref) {  

  for my $val (values %ref) {
    if (not defined $val) {next;}  # some values are UNDEF
    if (exists ($catches{$val})) {next;}  # values are only entered once
    $catches{$val} = "0";
  }

    my @dyad = qw(--- ---);
    
    @terms = split(/\s+/, $body);
    my $termNum = @terms;
  
  TERM4: for (my $i = 0; $i <= $termNum-4; ++$i) { # 4-gram
    $_ = $terms[$i]." ".$terms[$i+1]." ".$terms[$i+2]." ".$terms[$i+3];
    if ($_ =~ /^\s*$/) {next TERM4;} # skip blanks and empties
    $_ =~ s/^[^\w]//; # remove beginning non-word chars
    $_ =~ s/[^\w]$//; # remove ending non-word chars
    $_ = &TrimString($_); 
    $_ = "\U$_"; #make it capital
   #     print "$_\n"; #checks out nicely

    if(defined($ref{$_})) {
      $catches{$ref{$_}}++;
      $terms[$i] = ""; $terms[$i+1] = ""; $terms[$i+2] = ""; $terms[$i+3] = "";
      $i = $i+3;
    }
  } # end  for

  TERM3: for (my $i = 0; $i <= $termNum-3; ++$i) { # 3-gram
    $_ = $terms[$i]." ".$terms[$i+1]." ".$terms[$i+2];
    if ($_ =~ /^\s*$/) {next TERM3;} # skip blanks and empties
    $_ =~ s/^[^\w]//;
    $_ =~ s/[^\w]$//;
    $_ = &TrimString($_);
    $_ = "\U$_"; #make it capital

    if(defined($ref{$_})) {
      $catches{$ref{$_}}++;
      $terms[$i] = ""; $terms[$i+1] = ""; $terms[$i+2] = "";
      $i = $i+2;
    }
  }
  
  TERM2: for (my $i = 0; $i <= $termNum-2; ++$i) { # 2-gram
    $_ = $terms[$i]." ".$terms[$i+1];
    if ($_ =~ /^\s*$/) {next TERM2;} # skip blanks and empties
    $_ =~ s/^[^\w]//;
    $_ =~ s/[^\w]$//;
    $_ = &TrimString($_);
    $_ = "\U$_"; #make it capital

    if(defined($ref{$_})) {
      $catches{$ref{$_}}++;
      $terms[$i] = ""; $terms[$i+1] = "";
      $i = $i+1;
    }
  }
                  
  TERM: for (my $i = 0; $i <= $termNum-1; ++$i) { # 1-gram
    $_ = $terms[$i];
    if ($_ =~ /^\s*$/) {next TERM;} # skip blanks and empties
    $_ =~ s/^[^\w]//;
    $_ =~ s/[^\w]$//;
    $_ = &TrimString($_);
    $_ = "\U$_"; #make it capital

    if(defined($ref{$_})) {
      $catches{$ref{$_}}++;
      $terms[$i] = "";
      next TERM;
    }

    $_ = lc $_; #making string lowercase
    $_ =~ s/[^\w]//g;

    if($stemFunc !~ m/NO/i) { 
      $_ = &$stemFunc($_); 
    }  # stem the word

    if ($_ =~ /\d+/) {next TERM;} # skip numbers
    if (exists($stopHash{$_})) {next TERM;} # skip stopwords   
    if ($_ =~ /^\s*$/) {next TERM;} # skip blanks and empties
        
    push(@termArray, "$_ ");
  }

  $dyad[0] = (sort {$catches{$b} <=> $catches{$a}} keys %catches)[0];
  $dyad[1] = (sort {$catches{$b} <=> $catches{$a}} keys %catches)[1];
  if (length($dyad[1]) == 0) {$dyad[1] = $dyad[0];}
  $ssOut[$ssCount-1].="$dyad[0]\t$dyad[1]\n";
  
  return @termArray;

  } # end if %ref is not empty
    
  else {
    my @words = split(/\s+/, $body);
    foreach(@words) {
      $_ = lc $_; #making string lowercase
      $_ =~ s/[^\w]//g;
      $_ = &TrimString($_);

      if($stemFunc !~ m/NO/i) { 
	$_ = &$stemFunc($_); 
      }  # stem the word

      if ($_ =~ /\d+/) {next;} # skip numbers
      if (exists($stopHash{$_})) {next;} # skip stopwords   
      if ($_ =~ /^\s*$/) {next;} # skip blanks and empties
        
      push(@termArray, "$_ ");
    }
    $ssOut[$ssCount-1].="\n";
    return @termArray;
  } # end else

}  # end subroutine

     


#################
## openning files

open(DOCIN, "documents.txt")    or die("Could not open documents.txt");
open(DOCOUT, ">tokens.txt")             or die("Could not open tokens.txt file");
open(SS, ">spreadsheet.tsv")             or die("Could not open spreadsheet.tsv file");

if($rmact ne "NO") { 
  open(DAT, $rmact)             or die("Could not open $rmact file");
}
  


#############################
# establish the stopword hash

open(STOPS, $stopsFile) or die "Can\'t open stop words file $stopsFile; error $!";
while(my $sw = <STOPS>) {
  my @stopwords = split(/\s+/, $sw);
  foreach(@stopwords) {
    $_ = lc $_; #making string lowercase
    $_ =~ s/[^\w]//g;
    $_ = &TrimString($_);
    $stopHash{$_} = undef;
  }
}
close(STOPS);

##############################
# import the stemming function

if($stemFile !~ m/NO/i) {
  if ($stemFile =~ m/(.+).pm/) {
    $stemFunc = $1;
    eval"use $stemFunc"; # inport the stemming subroutine from a .pm file
  }
}
else {$stemFunc = $stemFile;}

######################################################
# ESTABLISH COUNTRY CODES HASH
# extract CountryCode, CountryName, Nationality and MajorCities from CountryCodes file
# the arrays - natn & code - and the index - nnat - store these values
# NOTE: this is optional.
######################################################

if($rmact ne "NO") {
 my @natn = ();
 my @code = ();
 my $sstr = "";
 my $ccode = "";

 my $on = 0;
 CCODE: while ($line = <DAT>) {
  if($line =~ m/-->/) {$on = 1;}
  if($on == 0) {next CCODE;}

  if ($line =~ m/CountryCode>/) {
	  $line =~ m/>(\w+)</;
		$ccode = $1;
  }  
  if ($line =~ m/ISO3166-alpha3>/) {
    $line =~ m/>(\w+)</;
    if(length($1) ne 0) {$ccode = $1;}
  }

  elsif ($line =~ m/CountryName>/) {
    $line =~ m/>(.+)</;
    $sstr = $1; 
	  $sstr =~ tr/_/ /; #remove the underscores
		push(@natn, $sstr);
    push(@code, $ccode);
   	push(@natn, $sstr."'S"); 
   	push(@code, $ccode);
  }

  elsif ($line =~ m/Nationality>/) {
    while($line = <DAT>) {
      last if($line =~ m/Nationality>/);
	    $sstr = &TrimString($line);
	    $sstr =~ tr/_/ /;
  		push(@natn, $sstr);
      push(@code, $ccode);
		  if ($sstr !~ m/S\Z/) { # doesn't match 'S' at the end of the string
     		push(@natn, $sstr."S");
        push(@code, $ccode);
		  }
    } 
  }

  elsif ($line =~ m/Capital>/) {
    while($line = <DAT>) {
      last if($line =~ m/Capital>/);
	    $sstr = &TrimString($line);
	    $sstr =~ tr/_/ /; #replace underscores	 
  		push(@natn, $sstr);
      push(@code, $ccode);
	    if ($sstr !~ m/S\Z/) {
     		push(@natn, $sstr."\'S"); #form plural
        push(@code, $ccode);
		  }
    } 
  }

  elsif ($line =~ m/MajorCities>/) {
	  while ($line = <DAT>) {
	    last if($line =~ m/MajorCities>/);
	    $sstr = &TrimString($line);
	    $sstr =~ tr/_/ /;
  		push(@natn, $sstr);
      push(@code, $ccode);
      if ($sstr !~ m/S\Z/) {
     		push(@natn, $sstr."\'S"); #form plural
        push(@code, $ccode);
		  }
    }
  }
  
  elsif ($line =~ m/Regions>/) {
	  while ($line = <DAT>) {
	    last if($line =~ m/Regions>/);
	    $sstr = &TrimString($line);
	    $sstr =~ tr/_/ /;
  		push(@natn, $sstr);
      push(@code, $ccode);
      if ($sstr !~ m/S\Z/) {
     		push(@natn, $sstr."\'S"); #form plural
        push(@code, $ccode);
		  }
    }
  }  
  
  elsif ($line =~ m/GeogFeatures>/) {
	  while ($line = <DAT>) {
	    last if($line =~ m/GeogFeatures>/);
	    $sstr = &TrimString($line);
	    $sstr =~ tr/_/ /;
  		push(@natn, $sstr);
      push(@code, $ccode);
      if ($sstr !~ m/S\Z/) {
     		push(@natn, $sstr."\'S"); #form plural
        push(@code, $ccode);
		  }
    }
  }

} #end CCODE while loop

# establish the hash, key is natn, value is code
 @natref{@natn} = @code;
 close(DAT);
} # end if rmact doesn't equal no
#open(TEMP, ">temp.txt");
#my $key2 = "";
#my $value2 = "";
#while (($key2, $value2) = each(%natref)){
#     print TEMP "$key2,$value2\n";
#}
#close(TEMP);
#die;
# end establish country codes hash
#####################################################

################################
## read in docs and prepare text

DOCS: while ($line = <DOCIN>) {
  $line = &TrimString($line);
  $mdata.="$line\n";
  if ($line !~ m/--------------/g && $line !~ m/>>>>>>>>>>>>/g && $line =~ m/\S/) {
    $ssOut[$ssCount] .= "$line\t";
  }
  if ($line =~ m/>>>>>>>>>>>>>>>>>>>>>>/) {  # story
    print DOCOUT $mdata;
    $mdata = "";
    ++$ssCount;
    STORY: while ($line = <DOCIN>) {
      #$line = &TrimString($line);
      if ($line =~ m/<<<<<<<<<<<<<<<<<<<<<</) {
	my @tokens = &PrepText($text, \%natref);
	print DOCOUT @tokens;
	print DOCOUT "\n<<<<<<<<<<<<<<<<<<<<<<\n";
	$text = "";
	last STORY;
      }
      $text.=$line;
    }
  }
}

print SS @ssOut;

close(DOCIN);
close(DOCOUT);
close(SS);


my $time_2 = time();
my $diff = $time_2 - $time_1;
print "\n\aFinished tokenization in $diff seconds.\n";
exit;




