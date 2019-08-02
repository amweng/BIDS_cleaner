function TSVfiles = trackTSV(directory)
%------------------------------------------------------------------------
% returns a struct with all .tsv files
%------------------------------------------------------------------------
    filePattern = fullfile (directory, '*.tsv');
    TSVfiles = dir(filePattern);
   
end
