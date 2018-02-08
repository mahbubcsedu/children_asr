#! /usr/bin/perl
####################################################################
###
### script name : MissingWordsCleanup.pl
### version: 0.1
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2007.5.20
### Command: perl ./MissingWordsCleanup.pl
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
# cleans up the following Festival output:
# festival> (set! fd (fopen "missingwords" "r")) #<FILE 0xa2f4b0 missingwords>
# festival> (lex.lookup (set! entry (readfp fd)))
# ("ABOMINATE" nil (((ax b) 0) ((aa m) 1) ((ax n) 0) ((ey t) 1)))
# ...

use strict;
my $debug =1;
# Festival can't process some words with single quotes - these need to be hand-edited in the "MissingWords" File before running this program!
my $festivalcommand = q|#!/usr/bin/festival --script
(let
    (
      (ifd (fopen "MissingWords" "r"))
      (ofd (fopen "temp" "w"))
      (word)
    )
    (while 
      (not (equal? (set! word (readfp ifd)) (eof-val)))
        (format ofd "%l\n" (lex.lookup word nil))
    )
    (fclose ifd)
    (fclose ofd)
)|;
open(SCHEME, ">MissingWordsPhonemes.scm") or die ("Can't write to MissingWordsPhonemes.scm");
print SCHEME $festivalcommand;
close SCHEME;

my $command = ("festival -b MissingWordsPhonemes.scm"); print "$command\n" if $debug; system($command) == 0  or die "system $command failed: $?";    
my $command = ("rm -f MissingWordsPhonemes.scm"); print "$command\n" if $debug; system($command) == 0  or die "system $command failed: $?"; 

open(IN, "<temp") or die ("cannot open MissingWords_out for input"); 
my @eText = <IN>; # slurp in entire file into an array
close(IN);
my $command = ("rm -f temp"); print "$command\n" if $debug; system($command) == 0  or die "system $command failed: $?"; 
####################################################################
### Cleans up eText and generates prompts file
open(OUT, ">MissingWords_out") or die ("MissingWords_out");
foreach my $line (@eText) { 
	$line =~ s/\d\)//g; # remove any number follwed by a parenthese
	$line =~ s/\(//g; # remove parenthesis	
	$line =~ s/\)//g; # remove parenthesis	
	$line =~ s/\"//g; # remove all double quotes
	$line =~ s/nil//g;
	$line =~ s/\s/ /g;
	$line =~ s/  / /g;
	my @line = split / /,$line;
	my $filename = shift(@line);
	if (!($line =~ /festival>/)) {
		print OUT "$filename    [$filename]    @line\n";	
	}
}
close (OUT);
