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
        fprintf(1, 'Could not load peaktable file named %s; molecule coordinates were not added to dataset.',filename_pks);
    end

    % Store intensities and peak positions in output struct
    traces.donor = donor;
    traces.acceptor = acceptor;
    if exist("peaktable","var")
        traces.peaks.donor = peaktable(1:2:end,2:3);
        traces.peaks.acceptor = peaktable(2:2:end,2:3);
    else
        traces.peaks.donor = zeros(height(traces.donor),2);
        traces.peaks.acceptor = zeros(height(traces.donor),2);
    end
end