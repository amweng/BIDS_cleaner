function BIDS_tool()

%----------------------------------------------------------------------------------
% tool to auto-correct errors in BIDS data. (structure/syntax/convention)
%----------------------------------------------------------------------------------
   

 %%%   directory = uigetdir('select data directory');
 
    problemLog = {};
 
    directory = '/Users/andrewweng/Data/ds000116';
    
    if directory == 0
        disp("please select the data directory and try again");
        return
    end
    if directory ~= 0
   
        %Taskqueue
        
        subjectPaths = generateSubjectPaths(directory);
        jsonFiles = (trackJson(directory));
   %   
 
        problemLog{end+1} = fixJson(jsonFiles,directory,problemLog);
        problemLog{end+1} = fixTSV(subjectPaths,directory,problemLog);
        problemLog{end+1} = fixfmap(subjectPaths,problemLog);
        problemLog{end+1} = fixCorruption(subjectPaths,directory,problemLog);
        disp('=============================================');
        disp('BIDS repair complete');
        disp('=============================================');
        
        %Log all the problems encountered
        
      
        problemLines = {};
        
        
        hasProblem = false;
        if ~isempty(problemLog)
            disp('Problems encountered: ');     
            for i = 1:numel(problemLog)          
                problems = problemLog{i};               
                if ~isempty(problems)                   
                    for j = 1:numel(problems)
                        problemMessage = problems{j};
                        if(isstring(problemMessage))
                            disp(problemMessage);
                            hasProblem  = true;
                            problemLines{end+1,1} = problemMessage;
                        end
                    end
                end       
            end             
        end
        
        %prints problem log to a BIDS_tool_repairLog.txt
        if ~hasProblem
            problemLines{end+1} = "there were no problems with the dataset that BIDS_tool could identify";
            disp("no problems found in data volume");
        end
        
        problemLogOutput = directory + "/BIDS_tool_repairLog.txt";
        fid = fopen(problemLogOutput, 'w');
        if fid == -1, error('Could not create problemLog file'); end
        CharString = sprintf('%s\n', problemLines{:});
        fwrite(fid, CharString,'char');
        fclose(fid);
                 
        
        
        
        
        
        disp('=============================================');
        disp('done');
    end
end


%------------------------------------------------------------------------
% Functions -------------------------------------------------------------
%------------------------------------------------------------------------
%   functions: 
%              trackJSON(rootDirectory)
%              trackTSV(rootDirectory)
%              fixJson(jsonFiles,rootDirectory)
%              spaceToUnderscore(dirtyStr)
%              generateSubjectPaths(directory)
%              fixTSV(subjectpaths,datadirectory)
%              fixFMAP(
%               
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

function problemLog = fixJson(jsonFiles,dataDirectory,problemLog)
    for i = 1:numel(jsonFiles)    
        disp("fix JSON");
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
            
            if ~strcmp(cleanStr,stepZeroStr)
        
                filename = fullfile(dataDirectory, currentFilenameStr);
                fid = fopen(filename, 'w');
                if fid == -1, error('Could not create JSON file'); end
                fwrite(fid, cleanStr, 'char');
                fclose(fid);
                msg = ("repaired JSON formatting on: " + currentFilenameStr );
                disp(msg)
                problemLog{end+1} = msg;
            
            else
                 disp("no repair required on " + currentFilenameStr);
            end
        else
            disp("no repair required on: dataset_description.json");
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

function problemLog = fixTSV(subjectPaths,dataDirectory,problemLog)

    disp("fix TSV");
    for i = 1:numel(subjectPaths)
        subjectPath = subjectPaths(i);
        subjectFuncPath = string(subjectPath + "/func");
        subTSV = trackTSV(subjectFuncPath);
        
        for j = 1:numel(subTSV)
            
            isBroken = false;         
            CHECK = subTSV(j).name;
            tsvFile = fopen(subTSV(j).name);        
            if tsvFile ~= -1
                

                tline = fgetl(tsvFile);
                tlines = cell(0,1);
                numLine = 0;
                while ischar(tline)
                    numLine = numLine + 1;
                    onsetDurations = sscanf(tline,'%f');

                    %track if there is an error in the data
                    if numel(onsetDurations) < 2 && numLine ~= 1
                        isBroken = true;
                    end  

                    %if both onset and durations are present && the values are
                    %numbers, write the line.
                    if  numel(onsetDurations) >= 2
                            tlines{end+1,1} = tline;

                    elseif numLine == 1 
                            % we are in the header
                            fixedline = strrep(tline,' ','_');

                            if ~contains(fixedline, 'trial_type')
                                fixedline = strrep(fixedline,'trial','trial_type');
                                fixedline = strrep(fixedline,'trials','trial_type');
                                fixedline = strrep(fixedline,'trialname','trial_type');
                                fixedline = strrep(fixedline,'trial_name','trial_type');
                            end

                            %track if there is an error in the header
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
                    msg = ("fixed header and/or deleted problematic n/a on: " + subTSV(j).name + " ...");
                    disp(msg);
                    problemLog{end+1} = msg;

                elseif ~isBroken
                    disp("No repair needed on: " + subTSV(j).name );
                end                 
            else
                msg = "DATA CORRUPTION: there was an error opening " + CHECK ;
                disp(msg);
                problemLog{end+1} = msg;
            end           
        end     
        disp(' ');
    end
end


%-------------------------------------------------------------------------
% fixes issue: magnitude1.json and magnitude2.json should not reside in the
% fmap directory. (AA will throw an erroneous error if these are included)
%-------------------------------------------------------------------------
function problemLog = fixfmap(subjectPaths,problemLog)

    disp("fix FMAP");
    fmapModified = false;
    for i = 1:numel(subjectPaths)
        subjectPath = subjectPaths(i);
        subjectFmapPath = string(subjectPath + "/fmap");
        fmapJSON = trackJson(subjectFmapPath);
        for j = 1:numel(fmapJSON)
            jsonName = fmapJSON(j).name;
            if contains(jsonName,'magnitude1') || contains(jsonName,'magnitude2')
                delete(subjectFmapPath + "/" + fmapJSON(j).name);
                disp("deleted unneeded: " + fmapJSON(j).name);
                fmapModified = true;
            end           
        end
        if fmapModified
            msg = ("deleted unneded magnitude1.json && magnitude2.json from " + subjectPaths(i) + "/fmap");
            disp(msg);
            problemLog{end+1} = msg;
        else
            disp("no changes made to " + subjectPaths(i) + "/fmap");
        end        
    end
end

%-------------------------------------------------------------------------
% Scan the volume for corrupted files and if found, eject the subjects 
% with corrupted files from the volume. Create an alert upon removal.
%-------------------------------------------------------------------------
function problemLog = fixCorruption(subjectPaths,directory,problemLog)

    disp(" ");
    disp("check Corruption");  
    isCorrupted = false;
    corruptionLog = {};

    for i = 1:numel(subjectPaths)
    
        dataFolders = {};
        subjectPath = subjectPaths(i);
        allDirs = dir(string(subjectPath));
        
        for (k = 1:numel(allDirs))
            dirName = (allDirs(k).name);
            if(~strcmp(dirName,'.') && ~strcmp(dirName,'..'))
                dataFolders{end+1} = allDirs(k);
            end
        end

        for j = 1:numel(dataFolders)
            
            dataFolder = (dataFolders{j});
            folderName = dataFolder.name;
            dataDir = dataFolder.folder;        
            folderPath = dataDir + "/" + folderName;
            filePattern = fullfile(folderPath, '*.gz');
            zippedFiles = dir(filePattern);
             
             
            for m = 1:numel(zippedFiles)
                fullFilePath = folderPath + "/" + zippedFiles(m).name;
                command = 'cd ' + folderPath + '; gzip -t -v ' + zippedFiles(m).name;
                [status,cmdout] = system(command);
                idx = regexp(cmdout,'uncompress failed');
                if ~isempty(idx)
                    msg = ("uncompress failed! : " + fullFilePath);
                    disp(msg);
                    isCorrupted = true;
                    
                    %log that there was a corruption
                    corruptionLog{end+1} = msg;                   
                    oldFileName = string(subjectPaths{i});                         
                    randomNum = randi([0,10000]);
                    newFileName = directory + "/corruptedSubject_"+randomNum;                   
                    msg = ("RENAMING SUBJECT WITH CORRUPTED FILE: " + subjectPaths{i} + " => 'corruptedSubject_" + randomNum +'');
                    disp(msg);
                    %log the rename
                    corruptionLog{end+1} = msg;                 
                    command = 'mv ' + oldFileName + ' ' + newFileName;
                    [status,cmdout] = system(command);
                end   
            end    
        end       
    end   
     if isCorrupted
        disp("===================================================");
        for r = 1:numel(corruptionLog)
             msg = ("DATA CORRUPTION: " + corruptionLog{r});
             disp(msg);
             problemLog{end+1} = msg;            
        end
     else
        disp("no corruption discovered in volume ");
     end  
end


%-------------------------------------------------------------------------
% Scan the volume for files that are supposed to be zipped/unzipped but are
% not. Repairs them and emits a log.
%-------------------------------------------------------------------------
function gzipChecker


end






