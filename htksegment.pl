#! /usr/bin/perl
####################################################################
###
### script name : htksegment.pl
### version: 0.1.2
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2007.03.22
### Command: perl ./htksegment [wav filename] [sample rate]
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
### Changes:                                                            
### 2007/06/12 - 0.1.2 - modularize code
####################################################################
use strict;
####################################################################
my $average_sentence_length = 10;
my $max_sentence_length = 15;
#my $min_pause_for_sentence_break = 200000; # HTK time format - 100 millisecond increments
my $min_pause_for_sentence_break = 2500000;
my (@max_sentences, $max_sentence_length_found, $max_sentence_length_linenumber, $min_sentence_length_linenumber);
my $min_sentence_length_found = $max_sentence_length;
my $up_increment = 1;
my $down_increment = -1;

my (%parms, $command);
$parms{"debug"} = 0;
$parms{"process_audio"} = 1;
####################################################################
my $debug = $parms{"debug"};
if ($#ARGV != 1) { 
 print "usage: [wav filename] [sample rate]\n";
 exit;
}
print "$ARGV[0]\n";
my $filename = $ARGV[0];
my $samplerate = $ARGV[1];
print "$ARGV[1]\n";
my ($filename_nosuffix) = split(/\./,$filename);

my $aligned_words = forceAlign(\%parms);
#print $aligned_words
print "this is the alined data $aligned_words\n";
segmentAudio(\%parms, $aligned_words);
print "htksegment\.pl completed!";

sub segmentAudio {
	my ($parms,$aligned_words) = @_;	
	my $debug = $$parms{"debug"};
	#print $params;
	#print $aligned_words;
	my $loop;
	my $true = 1;
	my $sentence_start = 0;
	my $sentence_end = $average_sentence_length;
	my $up = 1;
	my $down = 0;
  #print PROMPTS;
	my $fileid = 1;
	my @aligned_line = split(/ /,$$aligned_words[$sentence_end]);
	my ($word,$startTime,$endTime,$pause) = @aligned_line;	
	open(PROMPTS, ">wav/prompts") or die ("cannot open wav/prompts for output");	
	while ($true) {
		$loop++;
		if ($up) {
			if (($sentence_end + $up_increment) <= @$aligned_words) {
				sentence_test ($parms, "up", $up_increment, $aligned_words, \$fileid, \$sentence_start, \$sentence_end);
				$up = 0;
				$down = 1;
				$up_increment++;
			} elsif (($sentence_end + $up_increment) > @$aligned_words)	{ # catches last prompt line
				my $count;
				my $padded_fileid = sprintf("%04d",$fileid);
				print PROMPTS "$filename_nosuffix$padded_fileid ";				
				for ($count = $sentence_start; $count <= @$aligned_words; $count++) {
						my @aligned_line = split(/ /,$$aligned_words[$count]);
						($word,$startTime,$endTime,$pause) = @aligned_line ;
	                   	print PROMPTS ("$word ");
		    	}
		       	print PROMPTS"\n"; 
	  			# Process Audio
				my @firstword = split(/ /,$$aligned_words[$sentence_start]);		
				my @lastword = split(/ /,$$aligned_words[$sentence_end + $up_increment]);
				# !!!!!!	
				# insert pause that follows previous word
				my @previousword = split(/ /,$$aligned_words[$sentence_start-1]);	
				$startTime = $previousword[2]; # sentence end of previous word
				print "Sentence_start:$sentence_start:firstword: @firstword\n\tlastword:@lastword\n\tpreviousword:@previousword\n" if $debug;
				# !!!!!!
				my $endTime = $lastword[2] + $lastword[3];
				processAudio ($parms, $startTime, $endTime,$padded_fileid);			    	
				$true = 0;
			} 
		} elsif ($down) {
			if ((($sentence_end + $down_increment) >= 0) and (($sentence_end + $down_increment)>$sentence_start)){
				sentence_test ($parms, "down", $down_increment,$aligned_words, \$fileid, \$sentence_start, \$sentence_end);
				$down = 0;
				$up = 1;
				$down_increment--;
			} elsif ((($sentence_end + $down_increment) <= $sentence_start)) {
				$up = 1;
			} elsif (($sentence_end + $down_increment) < 0)  {
				die "Error\n";
			}
		}
	}
	
	$command = ("rm wav/temp.wav"); print "cmd:$command\n" if $debug; system($command); 
	print "\nSentence Length: min:$min_sentence_length_linenumber->$min_sentence_length_found; max:$max_sentence_length_linenumber->$max_sentence_length_found\n";
	print "\nSentences over max_sentence_length of $max_sentence_length words:\n";
	foreach my $line (@max_sentences) {
		print "\t$line\n";
	}	
}

sub forceAlign {
	my ($parms) = @_;	
	my $debug = $$parms{"debug"};	
	
	open(ALIGNED, "<aligned.out") or die ("can\'t open aligned\.out file for reading"); 
	my @aligned = <ALIGNED>;
	my ($pause, @aligned_words, $current_word, $current_startTime, $current_endTime);
	my $first_pass = 1;
	foreach my $line (@aligned) {
		my @labels = split(/ /, $line);
		my ($startTime,$endTime,$phone,$score,$word)= @labels;	
		chomp $word;
		if ($phone eq "sp") {
			$pause = $endTime - $startTime;
		}
		if (($word ne "") and ($word ne "SENT-END") and ($first_pass)) {	
			$current_word = $word;		
			$current_startTime = $startTime;
			$first_pass = undef;					
		} elsif (($word ne "") and (!$first_pass)) {	
			$current_endTime = $startTime-$pause;
			push (@aligned_words, "$current_word $current_startTime $current_endTime $pause");	
			$current_word = $word;		
			$current_startTime = $startTime;			
		}	
	}
	open(LOG, ">htksegment_log") or die ("cannot open htksegment_log for output");	
	foreach my $line (@aligned_words) {
		print LOG "$line\n";
	}
	close (LOG);
	print "####################################################################\n";
	return (\@aligned_words);
}

sub sentence_test {
	my ($parms, $where, $increment,$aligned_words, $fileid, $sentence_start, $sentence_end) = @_;
	my $debug = $$parms{"debug"};	
	
	my @aligned_line = split(/ /,$$aligned_words[$$sentence_end + $increment]);
	my ($word,$startTime,$endTime,$pause) = @aligned_line;
	if ($pause >= $min_pause_for_sentence_break) {
		my $count;
		my $padded_fileid = sprintf("%04d",$$fileid);
		print PROMPTS "$filename_nosuffix$padded_fileid ";	
		for ($count = $$sentence_start; $count <= $$sentence_end + $increment; $count++) {
				my @aligned_line = split(/ /,$$aligned_words[$count]);
				my ($word,$startTime,$endTime,$pause) = @aligned_line ;
               	print PROMPTS ("$word ");
    	}
       	print PROMPTS"\n"; 	
       	
		# Process Audio
		my @firstword = split(/ /,$$aligned_words[$$sentence_start]);		
		my @lastword = split(/ /,$$aligned_words[$$sentence_end + $increment]);	
		# !!!!!!
		if ($$sentence_start == 0) {
			$startTime = 0;
			print "Sentence_start:$$sentence_start:firstword: @firstword\n\tlastword:@lastword\n" if $debug;
		} else {
			# insert pause that follows previous word
			my @previousword = split(/ /,$$aligned_words[$$sentence_start-1]);	
			$startTime = $previousword[2]; # sentence end of previous word
			print "Sentence_start:$$sentence_start:firstword: @firstword\n\tlastword:@lastword\n\tpreviousword:@previousword\n" if $debug;
		}
		# !!!!!!
		my $endTime = $lastword[2] + $lastword[3];
		processAudio ($parms, $startTime, $endTime,$padded_fileid) ;
		# Calculate min and max sentence
		if ((($$sentence_end + $increment)-$$sentence_start) > $max_sentence_length) {
			my $wordcount = ((($$sentence_end + $increment)-$$sentence_start)+1);
			push (@max_sentences, "$filename_nosuffix$padded_fileid:$wordcount");
		} elsif ((($$sentence_end + $increment)-$$sentence_start) < $min_sentence_length_found) {
	    	$min_sentence_length_found = (($$sentence_end + $increment)-$$sentence_start)+1;
   			$min_sentence_length_linenumber = "$filename_nosuffix$padded_fileid";
	    } elsif ((($$sentence_end + $increment)-$$sentence_start) > $max_sentence_length_found) {
    		$max_sentence_length_found = (($$sentence_end + $increment)-$$sentence_start)+1;
    		$max_sentence_length_linenumber = "$filename_nosuffix$padded_fileid";
	    }
	    # Reset everthing to start looking for next set words delimited by a pause    	
		$$sentence_start = ($$sentence_end + $increment) + 1;
		$$sentence_end = ($$sentence_end + $increment) + $average_sentence_length;
		$up_increment = 0;
		$down_increment = 0;
		$$fileid++;		
	}
}

sub processAudio {
	my ($parms, $startTime, $endTime,$padded_fileid) = @_;
	my $debug = $$parms{"debug"};
	my $process_audio = $$parms{"process_audio"};
	
	#print "debug:$debug;process_audio:$process_audio:\n";
	if ($process_audio) {
		# HCopy can only process 16 bit files! 
		# HCopy does not create proper WAV/RIFF Headers!
		# make sure you use NATURALWRITEORDER = T and NATURALREADORDER = T	in the HTK config file	
		$command = ("HCopy -C copy_config  -s $startTime -e $endTime $filename wav/temp.wav"); print "cmd:$command\n" if $debug; system($command); 
		# sox command to create a proper wav file with a RIFF header; 
		#$command = ("sox  -t .raw -r $samplerate -sw wav/temp.wav wav/$filename_nosuffix$padded_fileid.wav"); print "cmd:$command\n" if $debug; system($command); 	
		$command = ("sox  -t .raw -r $samplerate -e signed-integer -b 16 wav/temp.wav wav/$filename_nosuffix$padded_fileid.wav"); print "cmd:$command\n" if $debug; system($command); 

		# !!!!!!	
		# use TARGETKIND=NOHEAD in HCopy command to remove 'click' noise that HCopy puts at the very beginning of each file it creates
	 	#$command = (" /usr/libexec/speech-tools/ch_wave wav/$filename_nosuffix$padded_fileid.wav -o wav/$filename_nosuffix$padded_fileid.wav -start 0.000070"); print "cmd:$command\n" if $debug; system($command); 		
		# !!!!!!
	 	print "wav/$filename_nosuffix$padded_fileid.wav\n" if not $debug;
	} else {
	 	print "wav/$filename_nosuffix$padded_fileid.wav\t$startTime:$endTime:\n" if $debug;
	}

}
