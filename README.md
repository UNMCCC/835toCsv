# 835toCsv

This repository offers a simple, procedural Perl script that parses 835 file formats, extracts Rx, payment and other useful info into user-friendly comma delimited format. The Perl script named 835_to_csv_batch.pl here extracts info from the cryptic 835 exchange format (pharma electronic remittance advice) reporting and will write out a user-friendly comma delimited file named like the original file in the same directory

Use:  either invoke perl  a35_to_CSV_batch.pl  or double click on it (provided Perl is configured properly)

Requirements: Source 835 Raw data files need to be in same folder as this script. Source file names need to start by "PT" (can be adapted to other providers). You will need a Perl interpreter to execute this script, in Windows, two popular free (for non-commercial uses) Perl interpreters are ActivePerl and DWIM.

Output: Filenames the same as source, but adds extension csv for correct interpretation in most environs.

Designed for a Windows environ, but should run OK on Nix, MacOS (untested on those other environs)

How? We just reverse engineer the format according to samples provided.

Note, different 3rd-party companies may interpret 835 file exchange differently.  Here, we tuned the script for one provider cvs-caremark. It may not work for other third parties, say, Express Scripts. However, the script can be adapted to the slight changes in 835 logic interpretation.  Send your tweaks, please.

