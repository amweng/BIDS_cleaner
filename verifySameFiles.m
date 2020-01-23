
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
    
    standardFiles = {};   
    filelist = dir(fullfile(string(subjectPaths(1)), '**/*.*'));
    for (i = 1:numel(filelist))
            filename = (filelist(i).name);
            if(~strcmp(filename,'.') && ~strcmp(filename,'..')&& ~strcmp(filename,'.DS_Store'))
            disp('subject 01: ' + string(filename));
            standardFiles{end+1} = filelist(i).name;   
            end
    end
    
    for (j = 2:numel(subjectPaths))
        subjectFiles={};
        testlist = dir(fullfile(string(subjectPaths(j)), '**/*.*'));
            for (i = 1:numel(testlist))
                filename = (testlist(i).name);
                if(~strcmp(filename,'.') && ~strcmp(filename,'..')&& ~strcmp(filename,'.DS_Store'))
                    subjectFiles{end+1} = testlist(i).name;   
                end
            end
        if numel(subjectFiles) ~= numel(standardFiles)
           msg = string(subjectPaths(j)) + " contains " + numel(subjectFiles) + " total files. expected: " + numel(standardFiles);
           discrepancyLog{end+1} = msg;
           hasDiscrepancy = 1;
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
