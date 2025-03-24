% Tests writing of each type of input data in the test_data folder to the
% OpenFRET format

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

% Paths to test data files
[currentPath,~,~] = fileparts(mfilename("fullpath"));
filenames{1} = strcat(currentPath,filesep,'test_data\Single-channel test\20250204_AJB_2_well_11_0001_driftcorrected_traces.dat');
filenames{2} = strcat(currentPath,filesep,'test_data\Two-channel test\STV_4NMRNA_wge80uM_50nmgcn4_fov-1.traces');
filenames{3} = strcat(currentPath,filesep,'test_data\Two-channel test - no pks\STV_4NMRNA_wge80uM_50nmgcn4_fov-1.traces');

fail = false;

% Iterate through all test files
for n = 1:numel(filenames)
   fprintf(1,'\nTest %d of %d: conversion of file %s...\n',n,numel(filenames),filenames{n});
   try 
        convertFiles(filenames(n),'title',title,...
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

        fprintf(1,'Successfully converted file to OpenFRET.\n');
   catch ME
        fprintf(1,'Failed to convert file to OpenFRET.\n');
        fprintf(1,['Exception: ',ME.message,'\n']);
        fail = true;
   end
end

if ~fail
    fprintf('\nAll tests passed.\n');
else
    fprintf('\nSome tests failed; review any exceptions.\n');
end