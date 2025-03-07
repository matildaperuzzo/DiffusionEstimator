clear
clc

% figure

% Add the directory containing run_model.m to the MATLAB path
addpath('src');
dataset = 'pinhasi';

if strcmp(dataset,'pinhasi')
    % load pinhasi
    pinhasi = readtable( ...
        'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

    pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

    pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
        {'lat', 'lon', 'bp'});

    pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
    pinhasi.bp = 2000 - pinhasi.bp; % from BP to year

    x = pinhasi.lat;
    y = pinhasi.lon;
    t = pinhasi.bp;

elseif strcmp(dataset,'cobo')
    % LOAD COBO et al

    cobo = readtable( ...
         'data/raw/cobo_etal/cobo_etal_data.xlsx');

    x = cobo.Latitude;
    y = cobo.Longitude;
    t = cobo.Est_DateMean_BC_AD_;
end

active_layers = [1 0 0 1 0 0 0 0];
parameters = data_prep(50, active_layers, x,y,t);

if strcmp(dataset,'cobo')
    parameters.A(76,39,46) = true;
end
% data_prep creates parameters struct with the following fields:
% parameters.A - initial matrix
% parameters.T - number of time steps
% parameters.terrain - terrain data
% parameters.dataset_idx - matrix storing index coordinates of dataset sites
% parameters.datset_lat - latitude of dataset sites
% parameters.dataset_lon - longitude of dataset sites
% parameters.dataset_bp - years before present of dataset sites
% parameters.dt - time step in years
% parameters.start_time - start time
% parameters.end_time - end time
% parameters.lat - first and last latitude
% parameters.lon - first and last longitude
% parameters.n - number of averages



%%

ranges = [[-2, -0.0]; [-2.0,0.0]];
n_points = 21;
[theta_min, on_edge, min_error, errors] = sweep(ranges, n_points, 0, parameters);
theta_0 = linspace(ranges(1,1), ranges(1,2), n_points);
theta_1 = linspace(ranges(2,1), ranges(2,2), n_points);
all_errors = reshape(errors, [n_points,n_points]);
% 
save("av_hydro.mat","all_errors","theta_0","theta_1",'-mat')
disp("Done!")

