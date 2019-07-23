function BIDS_tool()

%----------------------------------------------------------------------------------
% tool to auto-correct errors in BIDS data. (structure/syntax/convention)
%----------------------------------------------------------------------------------
   

    directory = uigetdir('select data directory');
    
    if directory == 0
        disp("please select the data directory and try again");
        return
    end
    if directory ~= 0
   
        %Taskqueue
        jsonFiles = (trackJson(directory));
        fixJson(jsonFiles,directory);
        subjectPaths = generateSubjectPaths(directory);
        fixTSV(subjectPaths,directory);
        fixfmap(subjectPaths,directory);
        disp('BIDS repair complete')
        disp('done');
    end
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
            cleanTabStr = regexprep(stepZeroStr, '\t', ' ');
            dirtyJsonStr = jsonencode(cleanTabStr);   
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
            disp("repair COMPLETE on: " + currentFilenameStr + "\ ...");



       
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

function fixTSV(subjectPaths,dataDirectory)

    disp("FIX TSV");
    for i = 1:numel(subjectPaths)
        subjectPath = subjectPaths(i);
        subjectFuncPath = string(subjectPath + "/func");
     %   disp(subjectFuncPath);
        funcFolder = dir(subjectFuncPath);
      %  disp(funcFolder);
        subTSV = trackTSV(subjectFuncPath);
        
        for j = 1:numel(subTSV)
            
            isBroken = false;
            
            tsvFile = fopen(subTSV(j).name);
            tline = fgetl(tsvFile);
            tlines = cell(0,1);
            numLine = 0;
            while ischar(tline)
                numLine = numLine + 1;
                onsetDurations = sscanf(tline,'%f');
                if numel(onsetDurations) < 2 && numLine ~= 1
                    isBroken = true;
                end                
                if  numel(onsetDurations) >= 2
                        
                       
                        tlines{end+1,1} = tline;
           
                elseif numLine == 1 
                        % we are in the header
                        noSpaces = strrep(tline,' ','_');
                        fixedline = strrep(noSpaces,'trial','trial_type');
                        fixedline = strrep(fixedline,'trials','trial_type');
                        fixedline = strrep(fixedline,'trialname','trial_type');
                        if ~strcmp(fixedline,tline) 
                            isBroken = true;
                        end
                        
                         tlines{end+1,1} = fixedline;
                end                
                tline = fgetl(tsvFile);
            end
            fclose(tsvFile);             
            %%%%%%%%% writing these back to directory%%%%%%
            
            if isBroken
                
                filename = fullfile(subjectFuncPath,"/",subTSV(j).name);
                fid = fopen(filename, 'w');
                if fid == -1, error('Could not create file'); end
                CharString = sprintf('%s\n', tlines{:});
                fwrite(fid, CharString,'char');
                fclose(fid);
                disp("repair COMPLETE on: " + subTSV(j).name + " ...");
                
            elseif ~isBroken
                
                disp("No repair needed on: " + subTSV(j).name );
                    
            end      
        end         
    end
end


%-------------------------------------------------------------------------
% fixes issue:  .json for magnitude 1 & 2 should not reside inside fmap
% dir
%-------------------------------------------------------------------------
function fixfmap(subjectPaths, directory)


end

