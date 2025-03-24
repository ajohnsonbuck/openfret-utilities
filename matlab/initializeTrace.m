function trace = initializeTrace(channel1, channel2)
    % Set properties of trace struct
    trace.channels(1).channel_type = channel1.type;
    trace.channels(1).data = [];
    trace.channels(2).excitation_wavelength = channel1.excitation_wavelength;

    trace.channels(2).channel_type = channel2.type;
    trace.channels(2).data = [];
    trace.channels(2).excitation_wavelength = channel2.excitation_wavelength;
end