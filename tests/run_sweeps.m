clear
clc

% figure

% Add the directory containing run_model.m to the MATLAB path
addpath('src');
rng(12) % set random seed

% choose whether to load pinhasi dataset or create a dataset
active_layers = [1 0 1 0 0];
cobo = readtable( ...
     'data/raw/cobo_etal/cobo_etal_data.xlsx');
parameters = data_prep(50, active_layers, cobo.Latitude, cobo.Longitude, cobo.Est_DateMean_BC_AD_);
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
ns = [10 50 100 500];

for n = ns
    parameters = data_prep(n, active_layers, cobo.Latitude, cobo.Longitude, cobo.Est_DateMean_BC_AD_);
    ranges = [[-1.46, -1.45];[0.64, 0.65]];
    n_points = 11;
    [theta_min, on_edge, min_error, errors] = sweep(ranges, n_points, 0, parameters);
    
    all_errors = reshape(errors, [n_points,n_points]);
    
    figure()
    pcolor(all_errors)
    title(n)
end