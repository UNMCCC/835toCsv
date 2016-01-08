# a35toCsv

A simple, procedural perl script that parses A35 file formats, extracts Rx, payment and other useful info into user-friendly comma delimited format

The script here extracts info from the cryptic archaic A35 exchange format (pharma claims/payments) reporting 

This script will output a user-friendly comma delimited file named like the original file

Use:  either invoke perl  a35_to_CSV_batch.pl  or double click on it

Requirements: Source Raw data files need to be in same folder as this script. Source file names need to start by "PT" (can be adapted to other providers).

Output: Filenames the same as source, but adds extension csv for correct interpretation in most environs.

Designed for a Windows environ, but should run OK on Nix, MacOS (untested on those other environs)

How? We just reverse engineer the format according to samples provided.

No further development expected at this point.

