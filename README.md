# 835toCsv

### Summary:
This repository offers a simple, procedural Perl script that parses (scrubs) 835 files. The script will extracts Rx, payment and other useful info and it will output this info into a user-friendly comma delimited spreadsheet. The Perl script named 835_to_csv_batch.pl here extracts info from the cryptic 835 exchange format (pharma electronic remittance advice) reporting and will write out a user-friendly comma delimited file named like the original file in the same directory or folder.

### Use  
Either type at the command line (shell) "perl a35_to_CSV_batch.pl" or double click on it (provided Perl is configured properly)

### Requirements: 

- The source 835 Raw data files, and those files need to be in same folder/directory as this script. Currently, the source file names need to start by "PT" (that is for CVS/Caremark, but it can be adapted to other providers). 

- A Perl interpreter to execute this script. If you are using Windows, two popular free (for non-commercial uses) Perl interpreters are ActivePerl and DWIM.

### Output: 

One spreadsheet per 835. The spreadsheet filename will be the same as source 835 file, but it will have the "csv" file extension for the correct association with Excel, etc.

### Notes:

Designed for a Windows environ, but should run OK on Nix, MacOS (untested on those other environs)

How? We just reverse engineer the format according to samples provided.

Note, different 3rd-party companies may interpret 835 file exchange differently.  Here, we tuned the script for one provider cvs-caremark. It may not work for other third parties, say, Express Scripts. However, the script can be adapted to the slight changes in 835 logic interpretation.  Send your tweaks, please.

