clear
clc

% figure

% Add the directory containing run_model.m to the MATLAB path
addpath('src');
rng(12) % set random seed

% choose whether to load pinhasi dataset or create a dataset
active_layers = [1 0 0 0 0];
cobo = readtable( ...
     'data/raw/cobo_etal/cobo_etal_data.xlsx');
parameters = data_prep(100, active_layers, cobo.Latitude, cobo.Longitude, cobo.Est_DateMean_BC_AD_);
% theory_theta = [0.15 0.05 0.1];
% parameters = create_dataset(theory_theta, 20, [53.0627, 43.6865]);
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

ranges = [[0.4, 0.401]];
n_points = 21;
[theta_min, on_edge, min_error, errors] = sweep(ranges, n_points, 0, parameters);

% all_errors = reshape(errors, [n_points,n_points]);
% 
% save("cobo_dataset_av_csi_2_start.mat","all_errors","all_gradients","theta_0","theta_1","theta_2","flag_1","flag_2",'-mat')
% disp("Done!")

