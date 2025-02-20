% Convert SiMREPS traces.dat files into OpenFRET format
function simreps2openfret()

compress = true;

% Set dataset attributes
dataset.title = '20250204_AJB_2: miRNA probe test';
dataset.description = 'Short probe test with miR-16 and miR-141';
dataset.experiment_type = '2-Color FRET';
dataset.authors = {'Alex Johnson-Buck'};
dataset.institution = 'The University of Michigan';
dataset.date = '2025-02-04';
dataset.metadata.experiment_id = '20250204_AJB_2'; % Example metadata
dataset.sample_details.buffer_conditions = '4X PBS';
dataset.sample_details.other_details.temperature = '28 C';
dataset.instrument_details.microscope = 'Olympus IX83 (Laser Bay 2)';
dataset.instrument_details.laser = '640nm';
dataset.instrument_details.detector = 'Hamamatsu Orca Fusion EMCCD';
dataset.instrument_details.other_details.objective = '60X 1.5 NA';

channel1.type = 'donor';
channel1.excitation_wavelength = 532;
channel1.emission_wavelength = 580;

channel2.type = 'acceptor';
channel2.excitation_wavelength = 640;
channel2.emission_wavelength = 680;

%----------------------------------------------

persistent filepath %Store user file path directory in between function calls   

if exist('filepath')==1 && (isa(filepath,"string") || isa(filepath,"char"))
    workingdir = pwd;
    cd(filepath)
end

% Open files
[filenames, filepath] = uigetfile("*_traces.dat","MultiSelect","on");

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
    if compress
        openfret.write(dataset, outfilename, 'compress');
    else
        openfret.write(dataset, outfilename);
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
    trace.channels(2).emission_wavelength = channel2.emission_wavelength;
    
    % Create dummy channel 2 to satisfy META-SiM Projector input
    % requirements
    trace.channels(1).channel_type = channel1.type;
    trace.channels(1).data = [];
    trace.channels(1).excitation_wavelength = channel1.excitation_wavelength;
    trace.channels(1).emission_wavelength = channel1.emission_wavelength;
end