################################################################################################
##
##   835 parser                             Inigo San Gil, Jan 2016
##
##   Description:    A program that extracts info from the cryptic 
##                   835 format (pharma claims/payments/elec. remittance advice) 
##                   reporting 
##                   This script will output a user-friendly
##                   comma delimited file named like the original file
##
##   to use:  either invoke perl  835_to_CSV_batch.pl  or double click on it
##
##   Requirements: Source Raw data files need to be in same folder as this
##   script. Source file names need to start by "PT" (can be adapted to other providers).
##   
##   Output: Filenames the same as source, but adds extension "csv" for correct
##   interpretation in most environs.
##
##   Desgined for Windows, but should run OK on Nix, MacOS too (untested on those environs)
##
##   Eng: Reverse engineers format according to samples provided
##
##   This is an example of a single CLP (clean and not a real record)
##   CLP2400724161.034.0715131527960514082140848120
##   CASCO9043.2191-0.15130-0.111300.11CASPR315
##   NM1QC1PALOTESPERIKOMI000029426001DTM23220151006SVCN4
##   1072200180161.0361.03
##
################################################################################################

use strict;
my $file; my $csvfile;
my $bpr; my $trn_eft; my $cchk;
my $clp_rx; my $clp_code; my $payer_per;
my $qc_pt;  my $trans_fee;
my $line; my $clp; my @clps;
my $payor;
my $amount_paid; my $pt_qc; my $datefilled;
my $after_clp; my $clp_reversed;
my $dirfee; my $trnfee; my $total_fees;

my @docfiles;
##
##  read all in a string
undef $/;

opendir(DIR,".") or die "$!";
@docfiles = grep(/PT\w+\s+\d+/, readdir(DIR));
closedir(DIR);
## Iterate through all the PT files.  (CVS, express scripts may begin by N..)
##
    
foreach $file (@docfiles) {
  
   if ($file =~/\.csv$/){ 
     next;   # Do not process processed files.
   }
   # Read the contents of the PT file
   open(DOC, "$file") or print("Error opening $file $!\n");
   $line = <DOC>;
   close(DOC);
  ##
  ##  let's open the output file, give it the same name, appends csv.
  $csvfile = $file.'.csv';

  open(FOUT, ">$csvfile") or die "Could not write out your comma delimited file \n";

  ## Parse (extract) the contents of the file

  ## clean out new lines -- unix encoding.
   $line =~ s/\n//g;

#  NOTE :  ▲ and ↔ are the actual field-delimiters in the file.
#  In here, we meticulously leverage them by matching .{1}  
#  other approaches may be neccessary.


  if ( $line =~ /BPR.{1}I.{1}(\d+)\.(\d+)/ ){
    $bpr = $1 . '.' . $2 ;
    print FOUT "Check Amount: $bpr,";
  }

  if ($line =~ /C.{1}CHK.{12}(\d+)/){
    $cchk = $1;
    print FOUT "Check Date: $cchk,";
  }

  if ($line =~ /(?<!B)PR.{1}(\w+)/){
    $payor = $1.$2;
    print FOUT "Payor: $payor,"
  }
  
  if ($line =~ /TRN.{1}(\d{1}).{1}(\d{10})/){
    $trn_eft = $2;
    print FOUT "Trn EFT: $trn_eft\n";

  }

  ##  Each CLP (claims paid) needs a number of things extracted.
  ##   - the Rx  (first #)
  ##   - Whether is a 1,2 or 4. (second #)
  ##   - Amount Paid (fourth #)
  ##   - PT (after QC) 
  ##   - Date Filled  (DTM 232)
  ##  
  ## print headers
  print FOUT "\n\nCLP Rx, Amount Paid, PT Name, Date Filled \n";
  print FOUT "CLAIMS PAID \n\n";
  @clps = split(/CLP.{1}/,$line);
  
  foreach $clp (@clps){
  
    $clp =~ s/\n//g;       ## removes newline characters (gets on way of pattern match)
    
    if ($clp =~ /^(\d{7}).{1}(\d{1})/){

      $clp_rx = $1;
      $clp_code = $2;
      $after_clp = $';

      if ($clp_code == 1){

        if($after_clp =~ /^.{1}\d+\.\d+.{1}(\d+)\.(\d+)/){
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^.{1}\d+.{1}(\d+)\.(\d+)/){   ## the 0 cents exception
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^.{1}\d+.{1}(\d+)/){   ## the 0 cents and also 0 cents exception
          $amount_paid = $1 . '.' . $2;   
        }
        $clp =~ /.{1}QC.{1}\d.{1}(\w+).{1}.(\w+)/;
        $pt_qc = $1 . ' ' . $2; 
        $clp =~ /DTM.{1}232.{1}(\d+)/;
        $datefilled = $1;
        print FOUT "$clp_rx, $amount_paid, $pt_qc, $datefilled \n";
      }elsif ($clp_code == 4){

        ## print "Rx REJECT is $clp_rx \n ";       ## ignore Reject Claims - can be included

      }elsif ($clp_code == 2){
        
        if($after_clp =~ /^.{1}\d+\.\d+.{1}(\d+)\.(\d+)/){
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^.{1}\d+.{1}(\d+)\.(\d+)/){   ## the 0 cents exception
          $amount_paid = $1 . '.' . $2;   
        }elsif($after_clp =~ /^.{1}\d+.{1}(\d+)/){   ## the 0 cents and also 0 cents exception
          $amount_paid = $1 . '.' . $2;   
        }
        $clp =~ /.{1}QC.{1}\d.{1}(\w+).{1}.(\w+)/;
        $pt_qc = $1 . ' ' . $2; 
        $clp =~ /DTM.{1}232.{1}(\d+)/;
        $datefilled = $1; 
        $clp_reversed .= $clp_rx .', ' . $amount_paid . ', ' . $pt_qc . ', ' . $datefilled . "\n";

      }

    }

  }
  if($after_clp =~ /AH.{1}43.{1}(\d+)\.(\d+)/ ){
    $trnfee = $1.'.'.$2;
  }elsif($after_clp =~ /AH.{1}43.{1}(\d+)/ ){
    $trnfee = $1;
  }
  if($after_clp =~ /CS.{1}62.{1}(\d+)\.(\d+)/ ){
    $dirfee = $1.'.'.$2;
  }elsif($after_clp =~ /CS.{1}62.{1}(\d+)/ ){
    $dirfee = $1;
  }
  $total_fees = $trnfee + $dirfee;
  print FOUT "TOTAL FEES $total_fees\n";
  print FOUT "CLAIMS REVERSED \n\n";
  print FOUT "$clp_reversed";

  close (FOUT);
}
