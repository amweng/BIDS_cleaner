function BIDS_tool()

%----------------------------------------------------------------------------------
% tool to auto-correct errors in BIDS data. (structure/syntax/convention)
%----------------------------------------------------------------------------------
   
   
    directory = uigetdir('select data directory');
   
   % directory = '/Users/andrewweng/Data/ds000170';
   
    addpath(genpath(directory));
    problemLog = {};
    
    if directory == 0
        disp("please select the data directory and try again");
        return
    end
    if directory ~= 0
   
        %Taskqueue
        
        subjectPaths = generateSubjectPaths(directory);
        jsonFiles = (trackJson(directory));
        problemLog{end+1} = fixJson(jsonFiles,directory,problemLog);
        problemLog{end+1} = fixTSV(subjectPaths,directory,problemLog);
        problemLog{end+1} = fixfmap(subjectPaths,problemLog);
        problemLog{end+1} = fixCorruption(subjectPaths,directory,problemLog);
        problemLog{end+1} = verifySameFiles(subjectPaths,directory,problemLog);
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
        
        disp('=============================================');
        disp("Writing repair log to BIDS_tool_repair_log.txt");
        problemLogOutput = directory + "/BIDS_tool_repair_log.txt";
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
                msg = ("WARNING: repaired JSON formatting on: " + jsonFiles(i).folder +"/"+ currentFilenameStr );
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

    tsvLog = {};

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
                    msg = ("WARNING: fixed header and/or deleted problematic n/a on: " + subTSV(j).name + " ...");
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
            msg = ("WARNING: deleted unneded magnitude1.json && magnitude2.json from " + subjectPaths(i) + "/fmap");
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
% Verify that all subjects contain the same files. 
% Each subject should contain the same number of files with the same naming.
% If a discrepancy is discovered, the subjects in question are marked and
% set aside.
%-------------------------------------------------------------------------
function problemLog = verifySameFiles(subjectPaths, directory, problemLog)
    
    disp(" ");
    disp("check for file consistency");  
    hasDiscrepancy = false;
    discrepancyLog = {};
    dataFolders = {};
    
    standardDirs = dir(string(subjectPaths(1)));    
    standardAnat = {};
    standardFunc = {};
    standardDWI = {};
    standardFMAP = {};

    
    for (k = 1:numel(standardDirs))
        dirName = (standardDirs(k).name);
        if(~strcmp(dirName,'.') && ~strcmp(dirName,'..')&& ~strcmp(dirName,'.DS_Store'))
            disp("the FIRST subject contains a(n) " + dirName + " folder.");
            dataFolders{end+1} = standardDirs(k);          
            folderName = (standardDirs(k).name);
            switch folderName
                case "anat"
                    anatContents = dir(subjectPaths(1) + "/" + folderName);
                    for l = 1:numel(anatContents)
                        fileNameStr = anatContents(l).name;
                        if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                            disp("    " + anatContents(l).name);
                            standardAnat{end+1} = anatContents(l).name;
                        end 
                    end       
                case "func"
                    funcContents = dir(subjectPaths(1) + "/" + folderName);
                    for l = 1:numel(funcContents)
                        fileNameStr = funcContents(l).name;
                        if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                            disp("    " + funcContents(l).name);
                            standardFunc{end+1} = funcContents(l).name;
                        end 
                    end
                case "dwi"
                    dwiContents = dir(subjectPaths(1) + "/" + folderName);
                    for l = 1:numel(dwiContents)
                        fileNameStr = dwiContents(l).name;
                        if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                            disp("    " + dwiContents(l).name);
                            standardDWI{end+1} = dwiContents(l).name;
                        end 
                    end
                case "fmap"
                    fmapContents = dir(subjectPaths(1) + "/" + folderName);
                    for l = 1:numel(fmapContents)
                        fileNameStr = fmapContents(l).name;
                        if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                            disp("    " + fmapContents(l).name);
                            standardFMAP{end+1} = fmapContents(l).name;
                        end 
                    end
            end              
        end
    end
    
    disp("--------------------------------------------------------------------------------");
    disp("comparing the rest of the volumes for consistency...");
    
    for i = 1:numel(subjectPaths)
        
        subjectDataFolders = {};
        subjectAnat = {};
        subjectFunc = {};
        subjectDWI = {};
        subjectFMAP = {};
            
        disp("-----------------------------------------------------");
        disp("checking: " + subjectPaths(i));   
        subjectDirs = dir(string(subjectPaths(i)));
        for j = 1:numel(subjectDirs)
            subjectDir = subjectDirs(j).name;
            if(~strcmp(subjectDir,'.') && ~strcmp(subjectDir,'..') && ~strcmp(subjectDir,'.DS_Store'))
                subjectDataFolders{end+1} = subjectDirs(j);
                folderName = subjectDirs(j).name;
               
                switch folderName
                    case "anat"
                        anatContents = dir(subjectPaths(i) + "/" + folderName);
                        for l = 1:numel(anatContents)
                            fileNameStr = anatContents(l).name;
                            if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                                subjectAnat{end+1} = anatContents(l).name;
                            end 
                        end       
                         disp("    This subject has " + numel(subjectAnat) + " anat files.");
                        if numel(subjectAnat) == numel(standardAnat)
                            disp("    This subject has the expected no. of anat files.");
                        else
                            msg = ("    This subject has " + numel(subjectAnat) + " anat files instead of the expected " + numel(standardAnat));
                            disp(msg)
                            discrepancyLog{end+1} ="WARNING: " + subjectPaths(i) + ":" + msg;
                            discrepancyLog{end+1} = "PLEASE CHECK: " + subjectPaths(i);
                            hasDiscrepancy = true;
                        end
                    case "func"
                        funcContents = dir(subjectPaths(i) + "/" + folderName);
                        for l = 1:numel(funcContents)
                            fileNameStr = funcContents(l).name;
                            if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                                subjectFunc{end+1} = funcContents(l).name;
                            end 
                        end
                        disp("    This subject has " + numel(subjectFunc) + " func files.");
                        if numel(subjectFunc) == numel(standardFunc)
                            disp("    This subject has the expected no. of func files. ");
                        else
                            msg = ("    This subject has " + numel(subjectFunc) + " func files instead of the expected " + numel(standardFunc));
                            disp(msg)
                            discrepancyLog{end+1} ="WARNING: " + subjectPaths(i) + ":" + msg;
                            discrepancyLog{end+1} = "PLEASE CHECK: " + subjectPaths(i);
                            hasDiscrepancy = true;
                        end
                    case "dwi"
                        dwiContents = dir(subjectPaths(i) + "/" + folderName);
                        for l = 1:numel(dwiContents)
                            fileNameStr = dwiContents(l).name;
                            if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                                subjectDWI{end+1} = dwiContents(l).name;
                            end 
                        end
                        disp("    This subject has " + numel(subjectDWI) + " dwi files.");
                        if numel(subjectDWI) == numel(standardDWI)
                            disp("    This subject has the expected no. of dwi files.");
                        else
                            msg = ("    This subject has " + numel(subjectDWI) + " dwi files instead of the expected " + numel(standardDWI));
                            disp(msg)
                            discrepancyLog{end+1} ="WARNING: " + subjectPaths(i) + ":" + msg;
                            discrepancyLog{end+1} = "PLEASE CHECK: " + subjectPaths(i);
                            hasDiscrepancy = true;
                        end
                    case "fmap"
                        fmapContents = dir(subjectPaths(i) + "/" + folderName);
                        for l = 1:numel(fmapContents)
                            fileNameStr = fmapContents(l).name;
                            if (~strcmp(fileNameStr,'.') && ~strcmp(fileNameStr,'..') && ~strcmp(fileNameStr,'.DS_Store'))
                                subjectFMAP{end+1} = fmapContents(l).name;
                            end 
                        end
                        disp("    This subject has " + numel(subjectFMAP) + " fmap files.");
                        if numel(subjectFMAP) == numel(standardFMAP)
                            disp("    This subject has the expected no. of fmap files.");
                        else
                            msg = ("    This subject has " + numel(subjectFMAP) + " fmap files instead of the expected " + numel(standardFMAP));
                            disp(msg)
                            discrepancyLog{end+1} = "WARNING: " + subjectPaths(i) + ":" + msg;
                            discrepancyLog{end+1} = "PLEASE CHECK: " + subjectPaths(i);
                            hasDiscrepancy = true;
                        end
                end
            end
        end         
        if numel(subjectDataFolders) ~= numel(dataFolders)
            msg = ("this subject is missing 1 or more data folders");
            disp(msg);
            discrepancyLog{end+1} = "WARNING: " + subjectPaths(i) + ":    does not contain the expected no. of data folders";
            discrepancyLog{end+1} = "PLEASE CHECK: " + subjectPaths(i);
            hasDiscrepancy = true;
        end   
    end
    % done checking subject volumes 
    if hasDiscrepancy
        disp("=============================================");
        for r = 1:numel(discrepancyLog)
             msg = (discrepancyLog{r});
             disp(msg);
             
             %write this to the problemLog
             problemLog{end+1} = discrepancyLog{r};            
        end
    else
        disp("no discrepancies discovered in volume ");
    end  
    
end


%-------------------------------------------------------------------------
% Scan the volume for files that are supposed to be zipped/unzipped but are
% not. Repairs them and emits a log.
%-------------------------------------------------------------------------
function problemLog = gzipChecker(subjectPaths, directory, problemLog)
    
    %TODO

end









