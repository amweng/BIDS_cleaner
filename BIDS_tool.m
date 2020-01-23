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
        disp('-------------------------------------------------------------');
        disp('BIDS scan complete');
        disp('-------------------------------------------------------------');
        
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
        
        disp('==============================================================');
        disp("Writing repair log to BIDS_tool_repair_log.txt");
        problemLogOutput = directory + "/BIDS_tool_repair_log.txt";
        fid = fopen(problemLogOutput, 'w');
        if fid == -1, error('Could not create problemLog file'); end
        CharString = sprintf('%s\n', problemLines{:});
        fwrite(fid, CharString,'char');
        fclose(fid);    
        disp('done');
    end
end
























