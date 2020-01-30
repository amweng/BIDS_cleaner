function problemLog = fixTSV(subjectPaths,dataDirectory,problemLog)

%-------------------------------------------------------------------------
% checks for "n/a" onset times and deletes rows where present
%-------------------------------------------------------------------------

    disp("fix TSV");
    
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
                %%%%%%%%% TODO log error with link to BIDS
                %%%%%%%%% specification%%%%%%%%%%%

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
