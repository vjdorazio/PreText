##  LN_mdata_1.pl
##  Last Updated February 27, 2012
##  Vito D'Orazio
##  The Pennsylvania State University
##  Department of Political Science
##  Contact: vjd125@psu.edu
##
##  program to extract meta-data from a corpus of Lexis-Nexis documents
##
##  execute in unix: perl LN_mdata_1.pl files.list CountryCodes.txt
##  IF the second argument is NO the program will not remove actors or predict dyad of interest.
##  Entering NO will speed up the program considerably.
##
##  output spreadsheet: dyads are ISO-3166, unless state is not in ISO, then its according to Schrodt coding
##
##  Output: spreadsheet.tsv, documents.txt, docs.noactors.txt
##
##  PROGRAM ORIGIN:
##  Adapted from the MID 4.0 Data Collection project, contact D'Orazio (vjd125@psu.edu) or Schrodt (schrodt@psu.edu)
##
##  Programming for origin files supported by National Science Foundation Political Science Program Grant
##  SES-0719634 "Improving the Efficiency of Militarized Interstate Dispute Data Collection using
##  Automated Textual Analysis" and SES-0924240, "MID4: Updating the Militarized Dispute Data Set
##  2002-2010."
##
##   Redistribution and use in source and binary forms, with or without modification,
##   are permitted under the terms of the GNU General Public License:
##   http://www.opensource.org/licenses/gpl-license.html
##
##  Report bugs to: vjd125@psu.edu
##
## List of compatible news sources by Lexis-Nexis Codes or Names:
## BBC, AP, New York Times, CNN, UPI, TASS, AFX, AFP, Xinhua, The Times London,
## DPA, The Gazette Montreal, Japan Economic Newswire, Interfax, Jerusalem Post

## List of subroutines: TrimString, Filter


#!/usr/local/bin/perl
use strict;
use warnings;
my $time_1 = time();

# ======== globals =========== #

my %month_number  = (  # hash used to translate dates
 Jan => '01', Feb => '02', Mar => '03', Apr => '04', May => '05', Jun => '06',
 Jul => '07', Aug => '08', Sep => '09', Oct => '10', Nov => '11', Dec => '12',
);

my $storyN=0; # document count
my $kfile=0; # number of input files processed
my $body=""; # text between a DOCS and LANGUAGE tags
my $filename = ""; # name of file read from files.list

# ======== subroutines =========== #


sub TrimString {
  $_[0] =~ s/^\s+//; #remove leading whites
  $_[0] =~ s/\s+$//; #remove trailing spaces
  $_[0] =~ s/\t/\ /; #remove tabs in string
  $_[0] =~ s/\r/\ /; #remove carriage return in string
  $_[0] =~ s/\n/\ /; #remove newline in string
  return $_[0];
}

sub Filter {
#takes a body between a DOC and language tags
#prints relevant news into output files

  # used for indexing purposes
  my $firsttext = '0';
  my $gotHL='0';
  my $ktext = 0;

  # text of news story
  my $text = ""; # the body of the news story

  # output per news story
  my $headline = "Headline Not Found";
  my $dateline = "Dateline Not Found";
  my $source = "Source Not Found";
  my $byline = "Byline Not Found";
  my $section = "Section Not Found";
  my $storylength = "Length Not Found";
  my $key = ""; # every story gets assigned a key after MATCH finishes
  my $date = "";
  

  my @values = split(/\n/,$_[0]);  

  MATCH: for(my $ka=0; $ka < @values; $ka++) {

    my $val = $values[$ka];

    # Skipping blank lines
    unless ($val =~ m/\S/) {next MATCH;}

    # Check to see if we have a "BYLINE"
    if ($val =~ m/BYLINE:/) {
      $byline = $val;
      next MATCH;
    }

    # Check to see if we have a "SECTION"
    if ($val =~ m/SECTION:/) {
      $section = $val;
      next MATCH;
    }

    # Check to see if we have a "LENGTH"
    if ($val =~ m/LENGTH:/) {
      $storylength = $val;
      next MATCH;
    }

    # Checking to see if we have a "DATELINE"
    if ($val =~ m/DATELINE:/) {
      $dateline = $val;
      next MATCH;
    }

    # The FIRST LINE OF TEXT is NEWS SOURCE
    if (($val =~ m/\w+/) && ($firsttext=='0')) {
       $firsttext = '1';
       $source = $val;
       next MATCH;
    }

    ## Avoiding "Edition" bugs for indexing the headline
    if ($val =~ m/\w+ Edition/ && ($ka < '10')) {
      $gotHL = ($ka+2); # the index of the headline
      next MATCH;
    }

    ## HEADLINE is always 2 lines after DATE, that means one line blank in the middle
    ## $gotHL is activated only after we retrieved the FIRST date
    if($gotHL eq $ka) {
      if($headline eq "Headline Not Found") {$headline = "";}
      $headline = $headline.$val." ";
      $gotHL = ($ka+1); # the index of the line after the first line of headline
      next MATCH;
    }

    ## Checking if the current line matches the DATE format
    if (($val =~ m/(\w+) (\d+), (\d\d\d\d)/)) {
      if($date eq "") {
        my $monthno = $month_number{substr($1,0,3)}; # convert month to numeric
	my $dayno = "";
        if (length($2) == 2) { $dayno = $2;}
        else {$dayno = "0".$2;}
        my $newdate = $3.$monthno.$dayno;
        $date=$newdate;
        $gotHL = ($ka+2); # the index of the headline
        next MATCH;
      }
    }
    
    ## Establishing the body of the text.
    ## The program rid.pl has been incorporated here.
    $text = $text.$val."\n";
    $text =~ s/^\s+//; #remove leading whites
    $text =~ tr/\x00-\x08//d;  #remove between 0-8 inclusive
    $text =~ tr/\x0B-\x1F//d;   #remove between 11-31
    $text =~ tr/\x80-\xFF//d;   #remove above 128-255

  } # end MATCH loop

  # Assign the story a key
  $key = "$date-$kfile-$storyN-$filename";

  ## FORMATTING AND PRINTING TO FILE RELEVANT INFORMATION ##

  $headline = &TrimString($headline);
  $source = &TrimString($source);
  $dateline = &TrimString($dateline);
  $date = &TrimString($date);
  $byline = &TrimString($byline);
  $storylength = &TrimString($storylength);
  $section = &TrimString($section);

  chomp($text);

  print FOUT "$headline\n";
  print FOUT "Key: $key\n";
  print FOUT "Date: $date\n";
  print FOUT "Source: "."$source\n";
  print FOUT "$dateline\n";
  print FOUT "$byline\n\n";
  print FOUT ">>>>>>>>>>>>>>>>>>>>>>\n";
  print FOUT "$text\n";
  print FOUT "<<<<<<<<<<<<<<<<<<<<<<\n";
  print FOUT "---------------------------------------------------------------\n\n";


  $storyN++; # count how many stories processed

} # end Filter subroutine

#####################################
# ======== main program =========== #
#####################################

# open files #
open(FDIR,"files.list")             or die "Can\'t open list of input file files.list; error $!";
open(FOUT, ">documents.txt")           or die "Can\'t open output file documents.txt; error $!";

# Read through the files (INFILE) in the file list (FDIR) 

FILELIST: while ($filename = <FDIR>) {
   
  chomp($filename);
  open(INFILE,"<$filename")  or die "Can\'t open input file $filename; error $!";
  my $line = <INFILE>;
  my $ke = 0;
  my $newStory = 0;

  FILE: while (!eof) {

    $line =~ s/^\s+//; #remove leading whites
    if ($line =~ m/\d+ DOCUMENTS/) {  #found a doc tag, extract body
      if (eof) {last;} 
      STORY: while ($line = <INFILE>) {
        if (eof) {last;} 
        if ($line =~ m/LANGUAGE:/)     {last;}  # these are various indicators of the end of the story
        if ($line =~ m/SUBJECT:/)       {last;}
        if ($line =~ m/ORGANIZATION:/) {last;}
        if ($line =~ m/GEOGRAPHIC:/)   {last;}
        if ($line =~ m/LOAD-DATE:/)     {last;}
        if ($line =~ m/PUBLICATION-TYPE:/)  {last;}
        if ($line =~ m/DOCUMENT-TYPE:/)  {last;}
        if ($line =~ m/\d+ of \d+ DOCUMENTS/) {
          $newStory = 1;
          last;
        }
 
        $body.=$line;
      } # end STORY loop

      # take the body and send it to the Filter subroutine
      &Filter($body);
      $body="";
      if($newStory == 1) {next FILE;}
   } #if found doc

    $line = <INFILE>; #go next line
    
  } # end FILE loop

  $kfile++; #count how many input files

} # end FILELIST loop

close(FOUT);
close(FDIR);

my $time_2 = time();
my $diff = $time_2 - $time_1;
print "\n\a $kfile files processed, $storyN stories in $diff seconds.\n";
exit;
