function BIDS_tool()

%----------------------------------------------------------------------------------
% tool to auto-correct errors in BIDS data. (structure/syntax/convention)
%----------------------------------------------------------------------------------

    % pointme at the top-level BIDS directory
    % 
    % Important: remember to add path to data
    %---------------------------------------------
%    directory = '/Users/andrewweng/Data/ds000107';
    directory = '/Users/andrewweng/Data/ds000116';
    %---------------------------------------------
    
    %Taskqueue
    jsonFiles = (trackJson(directory));
    fixJson(jsonFiles,directory);
    disp(directory);
    subjectPaths = generateSubjectPaths(directory);
    disp(subjectPaths);
    fixSubjectTSV(subjectPaths,directory);
    %complete
    disp('BIDS repair complete')
    disp('done');
end










%------------------------------------------------------------------------
% Functions -------------------------------------------------------------
%------------------------------------------------------------------------
%   functions: 
%              jsonFiles(rootDirectory)
%              fixJson(jsonFiles,rootDirectory)
%              spaceToUnderscore(dirtyStr)
%              subjectIterator(rootDirectory)
%              fixSubjectTSV(tsvFiles)
%
%


%------------------------------------------------------------------------
% returns a struct with all .json files
%------------------------------------------------------------------------

function jsonFiles = trackJson(directory)
    filePattern = fullfile (directory, '*.json');
    jsonFiles = dir(filePattern);
   
end

%------------------------------------------------------------------------
% returns a struct with all .tsv files
%------------------------------------------------------------------------

function TSVfiles = trackTSV(directory)
    filePattern = fullfile (directory, '*.tsv');
    TSVfiles = dir(filePattern);
   
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
% returns a cell array containing pathnames for each subject.
%-------------------------------------------------------------------------

function allSubPaths = generateSubjectPaths(directory)
    
    folder = dir(directory);
 
    allSubPaths = {};
 
    for index = 1:numel(folder)
        if(folder(index).name ~= "." && folder(index).name ~= "..")
                str = string(folder(index).name);
                if(regexp(str, regexptranslate('wildcard', 'sub*')))
                    x = folder(index).name;
                    pathname = [directory,'/',x];
                    allSubPaths{end+1} = pathname;
                end
        end
    end  
end




%-------------------------------------------------------------------------
% checks for "n/a" onset times and deletes rows where present
%-------------------------------------------------------------------------

function fixSubjectTSV(subjectPaths,dataDirectory)

    disp("FIX TSV");
    for i = 1:numel(subjectPaths)
        disp("eachSubject");
        subjectPath = subjectPaths(i);
        subjectFuncPath = string(subjectPath + "/func")
        disp(subjectFuncPath);
        funcFolder = dir(subjectFuncPath)
        disp(funcFolder);
        subTSV = trackTSV(subjectFuncPath);
        
        for j = 1:numel(subTSV)
            disp(subTSV(j));
            tsvFile = fopen(subTSV(j).name);
            tline = fgetl(tsvFile);
            tlines = cell(0,1);
            numLine = 1;
            while ischar(tline)
                onsetDurations = sscanf(tline,'%f');
                
                if  numel(onsetDurations) == 2
                     
                        tlines{end+1,1} = tline;
           
                elseif numLine == 1
                         tlines{end+1,1} = tline;
                end
                
                numLine = numLine + 1;
                
                tline = fgetl(tsvFile);
            end
            fclose(tsvFile);     
            disp(tlines);
            
            %%%%%%%%% writing these back to directory%%%%%%
            
            filename = fullfile(subjectFuncPath,"/",subTSV(j).name);
            disp(filename);
            fid = fopen(filename + "CLEANEDFINALagain", 'a');
            if fid == -1, error('Could not create file'); end
           
            CharString = sprintf('%s\n', tlines{:});
            fwrite(fid, CharString,'char');
            fclose(fid);
            disp("repair COMPLETE on: " + subTSV(j).name + " ...");

            
        end
        
        
         
    end
    

end


