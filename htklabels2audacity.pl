#! /usr/bin/perl
####################################################################
###
### script name : htklabels2audacity.pl
### version: 0.1
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2007.03.12
### Command: perl ./htklabels2audacity.pl [infile-HTKlabels] [outfile-AudacityLabels]
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

if ($#ARGV != 1) {
 print "usage: inputfilename outputfilename\n";
 exit;
}
$inputfilename = $ARGV[0];
$outputfilename = $ARGV[1];
open(IN, "<$inputfilename") or die ("need input file name"); 
open(OUT, ">$outputfilename") or die ("need output file name");

my @lines = <IN>;    

foreach my $line (@lines)    {
	chomp $line;
	my @labels = split(/ /, $line);
	my $startTime = shift @labels;
	my $audacity_startTime = (($startTime /10 ) / 1000000);
	my $endTime = shift @labels;	
	my $phone = shift @labels;	
	my $score = shift @labels;	
	my $word = shift @labels;	
#print OUT "$startTime $endTime $phone $score $word\n";	
	if ($word ne "") {
	    print OUT "$audacity_startTime $word\n";
	}		
}
close(IN);
close(OUT);