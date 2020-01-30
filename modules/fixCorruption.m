function problemLog = fixCorruption(subjectPaths,directory,problemLog)

%-------------------------------------------------------------------------
% Scan the volume for corrupted files and if found, renames the subjects 
% with corrupted files to "hide" from aa..
%-------------------------------------------------------------------------

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

