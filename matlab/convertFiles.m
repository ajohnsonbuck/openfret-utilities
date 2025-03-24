function convertFiles(filenames,varargin) 
% Convert SiMREPS traces.dat files into OpenFRET format
%{
Args 
    Required:
        filenames (cell array of string or char): names of files to be converted to OpenFRET
        path (string or char): path to files

    Optional name-value pairs:
        'compress' (logical): true or false -- specify whether to use zip compression (default = true)
        'title' (str): experiment title
        'description' (str): experiment description
        'experiment_type' (str): type of experiment (e.g., 'SiMREPS')
        'authors' (cell array of str or char): authors of experiment (e.g., {'Jane Doe', 'John Doe'})
        Other recommended metadata:
        'institution' (str): institution where the work was done
        'date' (str): date of experiment
        'experiment_id' (str): Unique ID of experiment
        'buffer_conditions' (str): Buffer used in experiment
        'temperature' (str): Temperature of experiment
        'microscope' (str): Microscope used
        'detector' (str): Detector used
        'objective' (str): Objective used
%}

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
if nargin > 2
    for n = 1:2:nargin-2
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

traceTemplate = initializeTrace(channel1,channel2);

% Iterate through files, load traces, and write .json for each dataset
for n = 1:numel(filenames)
    fprintf(1,'Creating OpenFRET file for input file %s ...\n',filenames{n});

    filepath = filenames{n};
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

        % Place intensity vs time data into channel 2
        dataset.traces(p).channels(2).data = acceptor(p,:);

        % Add peak xy positions, if they are present
        if exist("donorpks","var")
            dataset.traces(p).channels(1).xy = donorpks(p,:);
        end
        if exist("acceptorpks","var")
            dataset.traces(p).channels(2).xy = acceptorpks(p,:);
        end
    end

    % Write to file
    outfilename = strcat(filepath(1:end-suffixLength),'json');
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