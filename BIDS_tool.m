function BIDS_tool()

%----------------------------------------------------------------------------------
% tool to auto-correct errors in BIDS data. (structure/syntax/convention)
%----------------------------------------------------------------------------------

    % pointme at the top-level BIDS directory
    % 
    % Important: remember to add path to data
    %---------------------------------------------
  %  directory = '/Users/andrewweng/Data/ds000107';
    directory = '/Users/andrewweng/Data/ds000116';
    %---------------------------------------------
    
    %Taskqueue
    listContents(directory);
    jsonFiles = (trackJson(directory));
    fixJson(jsonFiles,directory);
    
    %complete
    disp('BIDS repair complete')
    disp('done');
end










%------------------------------------------------------------------------
% Functions -------------------------------------------------------------
%------------------------------------------------------------------------
%   functions: listContents(rootDirectory)
%              jsonFiles(rootDirectory)
%              fixJson(jsonFiles,rootDirectory)
%              spaceToUnderscore(dirtyStr)
%
%
%
%------------------------------------------------------------------------
% returns all non-dotfiles in the data directory
%------------------------------------------------------------------------

function listContents(rootDirectory)
    folderInfo = dir(rootDirectory);
    for index = 1:numel(folderInfo)
        if(folderInfo(index).name ~= "." && folderInfo(index).name ~= "..")
            a = folderInfo(index).name;
            %disp(folderInfo(index).name);
        end
    end
end


%------------------------------------------------------------------------
% returns a struct with all .json files
%------------------------------------------------------------------------

function jsonFiles = trackJson(rootDirectory)
    filePattern = fullfile (rootDirectory, '*.json');
    jsonFiles = dir(filePattern);
   
end


%------------------------------------------------------------------------
% fixes JSON files
%------------------------------------------------------------------------

function fixJson(jsonFiles,dataDirectory)
    for i = 1:numel(jsonFiles)    
        disp(" ");
        disp("file being repaired: " + jsonFiles(i).name);
        currentFilename = jsonFiles(i).name;
        currentFile = fopen(currentFilename,'r+');
        
        if (currentFile == -1)
            msg = ("Error opening: " + currentFilename + ". check correct path present");
            error(msg);
            break
        end 
       
        raw = fread(currentFile);
        chars = char(raw);
        dirtyStr = convertCharsToStrings(chars);
        fclose(currentFile);
        currentFilenameStr = string(currentFilename);
    
        if(currentFilenameStr ~= 'dataset_description.json')     
            stepZeroStr = spaceToUnderscore(dirtyStr);
            dirtyJsonStr = jsonencode(stepZeroStr);   
            stepOneStr = strrep(dirtyJsonStr,'\n','');
            stepTwoStr = strrep(stepOneStr,'""','');
            stepThreeStr = strrep(stepTwoStr,'\','');
            stepFourStr = strrep(stepThreeStr,'"{','{');
            cleanStr = strrep(stepFourStr,'}"','}');
   
            filename = fullfile(dataDirectory, currentFilenameStr);
            fid = fopen(filename, 'w');
            if fid == -1, error('Could not create JSON file'); end
            fwrite(fid, cleanStr, 'char');
            fclose(fid);
            disp("repair COMPLETE on: " + currentFilenameStr + " ...");

        else
            disp("no repair required on: dataset_description.json ...");
        end
        disp(" ");
    end
     disp("------------------------------------------------------");
     disp("JSON repair on root volume COMPLETE");
     disp("------------------------------------------------------");
end

%-------------------------------------------------------------------------
% convert spaces in strings to underscores and returns the cleaned string
%-------------------------------------------------------------------------
    
function cleanedStr = spaceToUnderscore(dirtyStr)
    cleanedStr = strrep(dirtyStr," ",'');
end


%-------------------------------------------------------------------------
% checks for "n/a" onset times and deletes rows where present
%-------------------------------------------------------------------------

function fixOneSubjectTSV(subjectPath)

end



    


