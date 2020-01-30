function problemLog = excludefmap(subjectPaths,problemLog)
%-------------------------------------------------------------------------
%  excludes magnitude1 and magnitude2 files from the fmap directory 
% (AA will throw an error if these are included)
%-------------------------------------------------------------------------

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