% Convert SiMREPS traces.dat files into OpenFRET format
function simreps2openfret(varargin)
% Args (name-value pairs) -- all are optional:
% 'compress' (logical): true or false -- specify whether to use zip compression (default = true)
% 'title' (str): experiment title
% 'description' (str): experiment description
% 'experiment_type' (str): type of experiment (e.g., 'SiMREPS')
% 'authors' (cell array of str or char): authors of experiment (e.g., {'Jane Doe', 'John Doe'})
% Other recommended metadata:
% 'institution' (str): institution where the work was done
% 'date' (str): date of experiment
% 'experiment_id' (str): Unique ID of experiment
% 'buffer_conditions' (str): Buffer used in experiment
% 'temperature' (str): Temperature of experiment
% 'microscope' (str): Microscope used
% 'detector' (str): Detector used
% 'objective' (str): Objective used

%% Default attributes
dataset.title = '(Title)';
dataset.description = '(Description of experiment)';
dataset.experiment_type = 'SiMREPS';
channel1.type = 'donor';
channel2.type = 'acceptor';
channel2.excitation_wavelength = 640;

compress = true; % Compress output to .zip file

%% Parse arguments
if nargin > 0
    for n = 1:2:nargin
        if strcmpi(varargin{n},'compress')
            if isa(varargin{n+1},'logical')
               compress = varargin{n+1};
            else
                error("'compress' value must be either true or false")
            end
        elseif strcmpi(varargin{n},'authors') || strcmpi(varargin{n},'author')
            if ~isa(varargin{n+1},'cell')
                dataset.authors = varargin(n+1);
            else
                dataset.authors = varargin{n+1};
            end
        elseif strcmpi(varargin{n},'experiment_id')
            dataset.metadata.experiment_id = varargin{n+1};
        elseif strcmpi(varargin{n},'buffer_conditions')
            dataset.sample_details.buffer_conditions = varargin{n+1};
        elseif strcmpi(varargin{n},'microscope')
            dataset.instrument_details.microscope = varargin{n+1};
        elseif strcmpi(varargin{n},'laser')
            dataset.instrument_details.laser = varargin{n+1};
        elseif strcmpi(varargin{n},'detector')
            dataset.instrument_details.detector = varargin{n+1};
        elseif strcmpi(varargin{n},'objective')
            dataset.instrument_details.objective = varargin{n+1};
        else 
            dataset.(varargin{n}) = varargin{n+1};  % Allow other user-specified fields
        end
    end
end


%% Load files and write OpenFRET

persistent filepath %Store user file path directory in between function calls   

if exist('filepath')==1 && (isa(filepath,"string") || isa(filepath,"char"))
    workingdir = pwd;
    cd(filepath)
end

% Open files
[filenames, filepath] = uigetfile('*_traces.dat; *_traces.mat',"MultiSelect","on");

if ~isa(filenames,"cell")
    if filenames==0
        disp('No filenames specified; aborting operation.');
        return
    end
    filenames = {filenames};
end

traceTemplate = initializeTrace(channel1,channel2);

% Iterate through files, load traces, and write .json for each dataset
for n = 1:numel(filenames)
    fprintf(1,['Creating OpenFRET file for input file ',filenames{n},'...\n']);
    tracesmat = load(strcat(filepath,filesep,filenames{n}),"-mat","traces");
    tracesmat = tracesmat.traces;
    ntraces = height(tracesmat);

    dataset.traces = repmat(traceTemplate, 1, ntraces); % Preallocate traces matrix

    fprintf(1,'Loading traces...\n');
    for p = 1:ntraces
        % Place intensity vs time data into channel 2
        dataset.traces(p).channels(2).data = tracesmat(p,:);

        % Create dummy channel 2 to satisfy META-SiM Projector input
        % requirements
        dataset.traces(p).channels(1).data = zeros(size(dataset.traces(p).channels(2).data));
    end

    % Write to file
    outfilename = strcat(filepath,filenames{n}(1:end-4),'.json');
    fprintf(1,'Traces loaded.\nWriting %s to file...\n',outfilename);
    openfret.write(dataset, outfilename);
    
    % Optionally, compress file
    if compress
        fprintf(1,'Compressing file %s to .zip...\n',outfilename);
        writeZip(outfilename);
    end

    dataset = rmfield(dataset,'traces'); % Reset traces struct for each new file
end

fprintf('Done.\n');

if exist("workingdir")
    cd(workingdir);
end

end

function trace = initializeTrace(channel1, channel2)
    % Set properties of trace struct
    % Place intensity vs time data into channel 2
    trace.channels(2).channel_type = channel2.type;
    trace.channels(2).data = [];
    trace.channels(2).excitation_wavelength = channel2.excitation_wavelength;
    
    % Create dummy channel 2 to satisfy META-SiM Projector input
    % requirements
    trace.channels(1).channel_type = channel1.type;
    trace.channels(1).data = [];
end

function writeZip(filename)
    zipfilename = strcat(filename,'.zip');
    zip(zipfilename,filename);
    delete(filename);
end