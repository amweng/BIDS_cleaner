function problemLog = fixJson(jsonFiles,dataDirectory,problemLog)

%------------------------------------------------------------------------
% cleans up erroneous characters in .json files
%------------------------------------------------------------------------
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