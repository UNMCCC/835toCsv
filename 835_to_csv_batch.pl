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
##   This is an example of a single (paid) CLP (clean and not a real record)
##   CLP2400724161.034.0715131527960514082140848120
##   CASCO9043.2191-0.15130-0.111300.11CASPR315
##   NM1QC1PALOTESPERIKOMI000029426001DTM23220131206SVCN4
##   1072200180161.0361.03
##
##    THis could be a reject (not a real thing) - note the 4 - 0 - 0, this seems to repeat consistently.
##    CLP160015140013153105501935119502860CASCO130-0.121300
##   .12160NM1QC1DOEJOHNMI353613148001DTM23220131102SVCN45901
##     104151000LQRX70
##
################################################################################################

use strict;
my $file; my $csvfile; my $bpr; my $trn_eft; my $cchk;
my $clp_rx; my $clp_code; my $payer_per;
my $qc_pt;  my $trans_fee;
my $line; my $clp; my @clps; my $payor;
my $amount_paid; my $pt_qc; my $datefilled;
my $after_clp; my $clp_reversed;
my $dirfee; my $trnfee; my $total_fees;
my $rebate=0; my $unrecov=0; my $overpymt=0; my $lumpsum=0; my $ip=0;
my $b3 = 0; my $fb =0; 
my $clp_rejected;

my @docfiles;
##
##  read all in a string
undef $/;

opendir(DIR,".") or die "$!";
@docfiles = grep(/PT/, readdir(DIR));
closedir(DIR);
## Iterate through all the PT files.  (CVS, express scripts may begin by N..)
##
    
foreach $file (@docfiles) {
  
   if ($file =~/\.csv$/){ 
     next;   # Do not process processed files.
   }
   ##
   ## Flush Line
   undef $line;
   
   # Read the contents of the PT file
   open(DOC, "$file") or print("Error opening $file $!\n");
   $line = <DOC>;
   close(DOC);
  ##
  ##  let's open the output file, give it the same name, appends csv.
  $csvfile = $file.'.csv';

  open(FOUT, ">$csvfile") or die "Could not write out your comma delimited file \n";
  
   print FOUT "835 filename $file \n";

  ## Parse (extract) the contents of the file
  
  ## clean out new lines -- unix encoding.
   $line =~ s/\n//g;

#  NOTE :  ▲ and ↔ are the actual field-delimiters in the file.
#  In here, we meticulously leverage them by matching .{1}  
#  other approaches may be neccessary.

  undef $bpr; undef $cchk; undef $payor;

  if ( $line =~ /BPR\x{1D}I\x{1D}(\d+)\.(\d+)/ ){
    $bpr = $1 . '.' . $2 ;
    print FOUT "Check Amount: $bpr,";
  }

  if ($line =~ /C.{1}CHK.{12}(\d+)/){
    $cchk = $1;
    print FOUT "Check Date: $cchk,";
  }

  if ($line =~ /(?<!B)PR\x{1D}(\w+)/){
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
  
  undef @clps;       ##  Flush buffers - do not carry over previous 835 data.
  undef $clp;  undef $clp_rx ;  undef $clp_code ;   undef $after_clp ;
  undef $amount_paid; undef $pt_qc;  undef $datefilled;
  undef $clp_reversed; $clp_rejected;
  
  @clps = split(/CLP\x{1D}/,$line);

  foreach $clp (@clps){
  
    $clp =~ s/\n//g;       ## removes newline characters (gets on way of pattern match)
    
    if ($clp =~ /^(\d{7})\x{1D}(\d{1})/){

      $clp_rx = $1;
      $clp_code = $2;
      $after_clp = $';

      if ($clp_code == 1){       ## 1 is paid, 4  reject, 22 reversal, 5 misc.

        if($after_clp       =~ /^\x{1D}\d+\.\d+\x{1D}(\d+)\.(\d+)/){
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^\x{1D}\d+\.\d+\x{1D}(\d+)\x{1D}/){   ## no cents in amount paid
          $amount_paid = $1 . '.00' ; 
        }elsif($after_clp =~ /^\x{1D}\d+\x{1D}(\d+)\.(\d+)/){   ## the 0 cents exception
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^\x{1D}\d+\x{1D}(\d+)\x{1D}/){   ## the 0 cents and also 0 cents exception
          $amount_paid = $1 . '.' . $2; 
        }else{ 
          $amount_paid = "failed";
        }
        
        ## last and first names may have spaces
        if($clp =~ /\x{1D}QC\x{1D}\d\x{1D}(\w+)\s(\w+)\x{1D}(\w+)/){
           $pt_qc = $1 . ' ' . $2 . ' ' . $3; 
        }elsif( $clp =~ /\x{1D}QC\x{1D}\d\x{1D}(\w+)\x{1D}(\w+)/){
            $pt_qc = $1 . ' ' . $2; 
        }
        $clp =~ /DTM\x{1D}232\x{1D}(\d+)/;
        $datefilled = $1;
        print FOUT "$clp_rx, $amount_paid, $pt_qc, $datefilled \n";
        
      }elsif ($clp_code == 4){

         if($clp =~ /\x{1D}QC\x{1D}\d\x{1D}(\w+)\s(\w+)\x{1D}(\w+)/){
           $pt_qc = $1 . ' ' . $2 . ' ' . $3; 
         }elsif( $clp =~ /\x{1D}QC\x{1D}\d\x{1D}(\w+)\x{1D}(\w+)/){
            $pt_qc = $1 . ' ' . $2; 
         }elsif( $clp =~ /\x{1D}QC\x{1D}\d\x{1D}NOT ON FILE/){
            $pt_qc = 'Not On File';         
         }
         $clp =~ /DTM\x{1D}232\x{1D}(\d+)/;
         $datefilled = $1; 
         $clp_rejected .= $clp_rx .', 0  , ' . $pt_qc . ', ' . $datefilled . "\n";

      }elsif ($clp_code == 2){
        
        if($after_clp       =~ /^2\x{1D}-?\d+\.\d+\x{1D}(-?\d+)\.(\d+)/){
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^2\x{1D}-?\d+\.\d+\x{1D}(-?\d+)\x{1D}/){   ## no cents in amount paid
          $amount_paid = $1 . '.00' ; 
        }elsif($after_clp =~ /^2\x{1D}-?\d+\x{1D}(-?\d+)\.(\d+)/){   ## the 0 cents exception
          $amount_paid = $1 . '.' . $2; 
        }elsif($after_clp =~ /^2\x{1D}-?\d+\x{1D}(-?\d+)\x{1D}/){   ## the 0 cents and also 0 cents exception
          $amount_paid = $1 . '.' . $2; 
        }else{
           $amount_paid = "failed";
        }
        
        if($clp =~ /\x{1D}QC\x{1D}\d\x{1D}(\w+)\s(\w+)\x{1D}(\w+)/){
           $pt_qc = $1 . ' ' . $2 . ' ' . $3; 
        }elsif( $clp =~ /\x{1D}QC\x{1D}\d\x{1D}(\w+)\x{1D}(\w+)/){
            $pt_qc = $1 . ' ' . $2; 
        }
        $clp =~ /DTM\x{1D}232\x{1D}(\d+)/;
        $datefilled = $1; 
        $clp_reversed .= $clp_rx .', ' . $amount_paid . ', ' . $pt_qc . ', ' . $datefilled . "\n";

      }elsif ($clp_code == 5){
          ##Misc code, warn
          print "Misc code on $after_clp\n";      
      }

    }
    
  }
 $rebate=0; $unrecov=0; $overpymt=0; 
 $lumpsum=0; $ip=0; $b3 = 0;  $fb =0;
  
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
  
   if($after_clp =~ /B2.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $rebate = $1.'.'.$2;
  }elsif($after_clp =~ /B2.{1}\d+.{1}(\d+)/ ){
    $rebate = $1;
  }
  
  if($after_clp =~ /WU.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $unrecov = $1.'.'.$2;
  }elsif($after_clp =~ /WU.{1}\d+.{1}(\d+)/ ){
    $unrecov = $1;
  }
  
  if($after_clp =~ /WO.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $overpymt = $1.'.'.$2;
  }elsif($after_clp =~ /WO.{1}\d+.{1}(\d+)/ ){
    $overpymt = $1;
  }
    
  if($after_clp =~ /LS.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $lumpsum = $1.'.'.$2;
  }elsif($after_clp =~ /LS.{1}\d+.{1}(\d+)/ ){
    $lumpsum = $1;
  }
  
  if($after_clp =~ /IP.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $ip = $1.'.'.$2;
  }elsif($after_clp =~ /IP.{1}\d+.{1}(\d+)/ ){
    $ip = $1;
  }
    
  if($after_clp =~ /B3.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $b3 = $1.'.'.$2;
  }elsif($after_clp =~ /B3.{1}\d+.{1}(\d+)/ ){
    $b3 = $1;
  }
  
  if($after_clp =~ /FB.{1}\d+.{1}(\d+)\.(\d+)/ ){
    $fb = $1.'.'.$2;
  }elsif($after_clp =~ /FB.{1}\d+.{1}(\d+)/ ){
    $fb = $1;
  }
  $total_fees = $trnfee + $dirfee;
   
  print FOUT "TOTAL FEES (Or/and Adjustments) $total_fees\n";
  if($rebate > 0){print FOUT " Rebate  $rebate\n"; }
  if($unrecov > 0){print FOUT " Unspecified Recovery  $unrecov\n"; }
  if($overpymt > 0){print FOUT "Overpayment  $overpymt\n"; }
  if($lumpsum > 0){print FOUT "Lump Sum  $lumpsum\n"; }
  if($ip > 0){print FOUT "Incentive Premium Paid $ip\n"; }
  if($b3 > 0){print FOUT "Recovery Allowance $b3\n"; }
  if($fb > 0){print FOUT "Forward Balance $fb\n"; }
  print FOUT "CLAIMS REVERSED \n\n";
  print FOUT "$clp_reversed";
  print FOUT "\n\n";
  print FOUT "CLAIMS REJECTED \n\n";
  print FOUT "$clp_rejected";
  close (FOUT);
}
