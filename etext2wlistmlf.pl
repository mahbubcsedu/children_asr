#! /usr/bin/perl
####################################################################
###
### script name : etext2wlist.pl
### version: 0.1
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2007.3.20
### Command: perl ./etext2wlist.pl eTextFilename [wav filename (no suffix)] 
###   
### Copyright (C) 2007 Ken MacLean
###
### This program is free software; you can redistribute it and/or
### modify it under the terms of the GNU General Public License
### as published by the Free Software Foundation; either version 2
### of the License, or (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###                                                              
####################################################################
use strict;

my $inputfilename = $ARGV[0];
my $wavfilename = undef;
if ($ARGV[1]) {
	$wavfilename = $ARGV[1];
}

open(IN, "<$inputfilename") or die ("cannot open input filename for input"); 
my @eText = <IN>; # slurp in entire file into an array
close(IN);

####################################################################
### Cleans up eText and generates prompts file
my @words;
foreach my $line (@eText) { # !!!!!! does this even get a chance to loop since all LFs and CRs have been removed????
	chomp $line; # remove all line feeds from the text file
	$line =~ s/\r//g; # remove all carriage returns from the text file
	$line =~ tr/a-z/A-Z/; # change to uppercase
	$line =~ s/,//g; # remove commas 
	$line =~ s/\.//g; # remove periods  
	#  $line =~ s/\'//g; # remove single quotes; but need words like "don't" - need to research this more ...
	$line =~ s/\"//g; # remove all double quotes
	$line =~ s/://g; # remove colon
	#  $line =~ s/-//g; # compound word dash; but VoxForge dictionnary contains words with dashes ...
	$line =~ s/--/ /g; #double dash
	$line =~ s/ - / /g; # dash punctuation	
	$line =~ s/ -/ /g; # dash punctuation		
	$line =~ s/-/ /g; # dash - compound word	
	$line =~ s/;//g; # semi-colon
	$line =~ s/!//g; # exclamation mark
	$line =~ s/\?//g; # question mark		
	$line =~ s/  / /g; # cleanup double spaces	
	$line =~ s/=//g; # remove equal sign
	$line =~ s/\(//g; # remove parenthesis	
	$line =~ s/\)//g; # remove parenthesis	
	$line =~ s/_//g; # remove underscore	
	# Other cleanup !!!!!! need to change the prompts files directly rather than doing this!!! or add to dictionnary!!!
	$line =~ s/&/AND/g; 
	
	my @wordlist = split(/ /,$line);
	foreach my $word (@wordlist) {
		if ($word =~ /\S/) {  #Anything other than white space 	[^ \r\t\n\f]
		$word =~ s/\s//g;
			push (@words, $word);
		}
	}
}
####################################################################
### create MLF file
if ($wavfilename) {
	open(MLF, ">words.mlf") or die ("cannot open words.mlf for output");
	print MLF "#!MLF!#\n"; # 
	print MLF "\"$wavfilename.lab\"\n";
	foreach my $word (@words) {
		print MLF "$word\n";
	}
	print MLF "\.\n";
	close (MLF);
}
####################################################################
### create WLIST file
push (@words, "SENT-END");
push (@words, "SENT-START");
my @words2 = sort(@words); 
my %seen;
my @uniq = grep !$seen{$_}++, @words2;
open(WLIST, ">wlist") or die ("cannot write to wlist");
foreach my $word (@uniq) {
		print WLIST "$word\n";
}
close(WLIST);


