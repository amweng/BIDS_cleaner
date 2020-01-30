function cleanedStr = spaceToUnderscore(dirtyStr)
%-------------------------------------------------------------------------
% convert spaces in strings to underscores and returns the cleaned string
%-------------------------------------------------------------------------   
    cleanedStr = strrep(dirtyStr," ",'');
end
