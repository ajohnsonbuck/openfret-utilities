%% User-defined options and metadata - modify this for each experiment

% Metadata
title = '(Experiment name goes here)';
description = '(Short description of instrument goes here)';
experiment_type = '(Experiment date goes here)';
authors = {'(Author of experiment)'};
institution = 'The University of Michigan';
date = 'YYYY-MM-DD';
experiment_id = 'YYYYMMDD_ABC_1'; % Recommended format: year_initials_experiment
buffer_conditions = '4X PBS';
temperature = '28 C';
microscope = 'Olympus IX83 (Laser Bay 2)';
detector = 'Hamamatsu Orca Fusion EMCCD';
objective = '60X 1.5 NA';
excitation_wavelength.channel1 = 532; % In nanometers
excitation_wavelength.channel2 = 640; % In nanometers

options.use_channel1 = true; % true = include channel 1 (green/donor) in OpenFRET; false = omit
options.use_channel2 = true; % true = include channel 2 (red/acceptor) in OpenFRET; false = omit

options.donor_crosstalk = 0.09; % (For 2-channel traces files): crosstalk of donor into acceptor channel, as fraction of donor-channel signal

%% Run conversion to OpenFRET
convertFiles('title',title,...
        'description',description,...
        'experiment_type',experiment_type,...
        'authors',authors,...
        'institution',institution,...
        'date',date,...
        'experiment_id',experiment_id,...
        'buffer_conditions',buffer_conditions,...
        'temperature',temperature,...
        'microscope',microscope,...
        'detector',detector,...
        'objective',objective,...
        'excitation_wavelength',excitation_wavelength,...
        'options',options);

%% Functions
function convertFiles(varargin) 
% Convert SiMREPS traces.dat files into OpenFRET format
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
channel1.excitation_wavelength = NaN;
channel2.type = 'acceptor';
channel2.excitation_wavelength = NaN;

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
        elseif strcmpi(varargin{n},'excitation_wavelength')
            channel1.excitation_wavelength = varargin{n+1}.channel1;
            channel2.excitation_wavelength = varargin{n+1}.channel2;
        elseif strcmpi(varargin{n},'options')
            options = varargin{n+1};
        else 
            dataset.(varargin{n}) = varargin{n+1};  % Allow other user-specified fields
        end
    end
end

% Check that at least one channel of data is included; abort operation
% otherwise
if ~(options.use_channel1) && ~(options.use_channel2)
    disp("At least one of options.use_channel1 and options.use_channel2 must be 'true'; aborting operation.");
    return
end


%% Load files and write OpenFRET

% Open files
[filenames, path] = uigetfile('*_traces.dat; *_traces.mat; *.traces',"MultiSelect","on");

cd(path);

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

    filepath = strcat(path,filenames{n});
    if strcmp(filepath(end-3:end),'.dat') || strcmp(filepath(end-3:end),'.mat')
        acceptor = openSiMREPStraces(filepath);
        donor = acceptor*0;
        suffixLength = 3;
    elseif strcmp(filepath(end-6:end),'.traces')
        traces2ch = openTraces(filepath,options.donor_crosstalk);
        donor = traces2ch.donor;
        donorpks = traces2ch.peaks.donor;
        acceptor = traces2ch.acceptor;
        acceptorpks = traces2ch.peaks.acceptor;
        if ~(options.use_channel1)
            donor = donor*0;
            donorpks = donorpks*0;
        elseif ~(options.use_channel2)
            acceptor = acceptor*0;
            acceptorpks = acceptorpks*0;
        end
        suffixLength = 6;
    end
    if all(donor==0)
       channel1.excitation_wavelength = NaN; % Set dummy donor channel wavelength to NaN
    elseif all(acceptor==0)
       channel2.excitation_wavelength = NaN; % Set dummy acceptor channel wavelength to NaN
    end

    ntraces = height(donor);

    dataset.traces = repmat(traceTemplate, 1, ntraces); % Preallocate traces matrix

    fprintf(1,'Loading traces...\n');
    for p = 1:ntraces
        % Place intensity vs time data into channel 2
        dataset.traces(p).channels(1).data = donor(p,:);
        dataset.traces(p).channels(1).xy = donorpks(p,:);

        % Place intensity vs time data into channel 2
        dataset.traces(p).channels(2).data = acceptor(p,:);
        dataset.traces(p).channels(2).xy = acceptorpks(p,:);
    end

    % Write to file
    outfilename = strcat(path,filenames{n}(1:end-suffixLength),'json');
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
    trace.channels(1).channel_type = channel1.type;
    trace.channels(1).data = [];
    trace.channels(2).excitation_wavelength = channel1.excitation_wavelength;

    trace.channels(2).channel_type = channel2.type;
    trace.channels(2).data = [];
    trace.channels(2).excitation_wavelength = channel2.excitation_wavelength;
end

function writeZip(filename)
    zipfilename = strcat(filename,'.zip');
    zip(zipfilename,filename);
    delete(filename);
end

function traces = openSiMREPStraces(filename)
% Args:
%   filename(string or char vector): path to file containing traces (*traces.dat, 'mat' format)
    traces = load(filename,'-mat');
    traces = traces.traces;
end

function traces = openTraces(filename, donor_crosstalk)
%Args:
    % filename(string or char) = path and filename of .traces file containing two-channel single-molecule data
    %            in binary (ieee-le) format
    % donor_crosstalk(double) = fraction of donor-channel signal that
    %                           appears in acceptor channel (typical value
    %                           = 0.09)

    % Open and read contents from binary traces file
    fid = fopen(filename,'r', 'ieee-le');
    len = fread(fid, 1, 'int32');
    Ntraces = fread(fid, 1, 'int16');
    raw = fread(fid,(Ntraces+1)*len,'int16');
    fclose(fid);
    
    % Initialize variables for 
    raw = reshape(raw,Ntraces+1,len);
    index=(1:(Ntraces+1)*len);
    Data=zeros(Ntraces+1,len);
    donor=zeros(Ntraces/2,len);
    acceptor=zeros(Ntraces/2,len);

    Data(index)=raw(index);

    % Parse intensity values from Data into separate donor and acceptor
    % matrices (row = trace, col = frame)
    for i=1:(Ntraces/2)
    donor(i,:)=Data(i*2,:);
    acceptor(i,:)=Data(i*2+1,:);
    end

    % Correct acceptor channel for donor crosstalk
    acceptor = acceptor - donor*donor_crosstalk;

    % Load peaktable
    try
    filename_pks = strcat(filename(1:end-7), '.pks');
    peaktable = load(filename_pks);
    catch
        error(sprintf('Could not load peaktable file named %s',filename_pks));
    end

    % Store intensities and peak positions in output struct
    traces.donor = donor;
    traces.acceptor = acceptor;
    traces.peaks.donor = peaktable(1:2:end,2:3);
    traces.peaks.acceptor = peaktable(2:2:end,2:3); 
end