% Open files for conversion to OpenFRET
function filenames = getFileNames()
    [filenames, path] = uigetfile('*_traces.dat; *_traces.mat; *.traces',"MultiSelect","on");
    
    cd(path);
    
    if ~isa(filenames,"cell")
        if filenames==0
            disp('No filenames specified; aborting operation.');
            return
        end
        filenames = {filenames};
    end

    for n = 1:numel(filenames)
        filenames{n} = strcat(path,filenames{n});
    end
end