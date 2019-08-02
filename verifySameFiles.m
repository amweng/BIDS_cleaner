
function problemLog = verifySameFiles(subjectPaths, directory, problemLog)

%-------------------------------------------------------------------------
% Verify that all subjects contain the same files. 
% Each subject should contain the same number of files with the same naming.
% If a discrepancy is discovered, the subjects in question are marked and
% set aside.
%-------------------------------------------------------------------------
    
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
