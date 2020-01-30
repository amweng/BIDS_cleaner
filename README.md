BIDS_tool
  tool to fix problems with "BIDS" data 

 	eventToUppercase
		TODO

 	fixCorruption
		% Scan the volume for corrupted files and if found, renames the subjects 	
		% with corrupted files to "hide" from aa..
 	excludefmap
		% excludes magnitude1 and magnitude2 files from the fmap directory 
 	fixJson
		% removes error-causing characters and syntax from JSON files
 	fixTSV
 		% fixes header names and remove onset times entered as 'n/a','na' or otherwise illegal values# 	getPaths
		% scans BIDS directory and adds subject paths for traversin
	spaceToUnderscore
		% GENERAL: converts spaces in strings to underscores and returns cleaned string
	getJson
		% scans BIDS directory for JSON files
	getTSV
		% scans BIDS directory for TSV files

