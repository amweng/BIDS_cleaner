function problemLog = eventToUppercase(directory,problemLog)
%EVENTTOUPPERCASE Summary of this function goes here
%   Detailed explanation goes here
    
    broken = false;
    tsvfiles = getTSV(directory);
    subjectPaths = getPaths(directory);
    for i = 1:numel(subjectPaths)
        subjectPath = subjectPaths(i);
        subjectFuncPath = string(subjectPath + "/func");
        subTSV = getTSV(subjectFuncPath);
        if isempty(subTSV)
            subjectFuncPath = string(subjectPath+"/*/func");
            subTSV = getTSV(subjectFuncPath);
        end
        if isempty(subTSV)
            subjectFuncPath = string(subjectPath+"/*/*/func");
            subTSV = getTSV(subjectFuncPath);
        end
        if isempty(subTSV)
            broken = true;
            msg = "could not find TSV in func dir";
        end
       tsvfiles(end+1: end+(length(subTSV))) = subTSV;
    end
    fullpaths = {};
    for j = 1:numel(tsvfiles)
        fullpaths{end+1} = string(tsvfiles(j).folder) + "/" + string(tsvfiles(j).name);
    end
    for k = 1:numel(fullpaths)
        tsvFile = fopen(string(fullpaths(k))); 
            if tsvFile ~= -1
                tline = fgetl(tsvFile);
                tlines = cell(0,1);
                numLine = 0;
                while ischar(tline)
                    numLine = numLine + 1;
                    tlines{end+1,1} = tline;               
                    tline = fgetl(tsvFile);
                end
            end
        for l = 2:numel(tlines)
            tlines(l) = upper(tlines(l));
        end
        
        fid = fopen(string(fullpaths(k)), 'w');
        if fid == -1, error('Could not create file'); end
        CharString = sprintf('%s\n', tlines{:});
        fwrite(fid, CharString,'char');
        fclose(fid);
    end
    if ~broken
        msg = "converted eventNames to uppercase";
    end
    disp(msg);
    problemLog{end+1} = msg;
    clear tlines


end

