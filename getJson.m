function jsonFiles = getJson(directory)
%------------------------------------------------------------------------
% returns a struct with all .json files
%------------------------------------------------------------------------

    filePattern = fullfile (directory, '*.json');
    jsonFiles = dir(filePattern);
   
end