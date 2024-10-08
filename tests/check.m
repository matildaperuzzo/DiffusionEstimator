clear
clc

% figure

% Add the directory containing run_model.m to the MATLAB path
addpath('src');
rng(12) % set random seed

theory_theta = [0.2, 0.1, 0.0];

% choose whether to load pinhasi dataset or create a dataset
% parameters = data_prep();
parameters = create_dataset(theory_theta,500, [53.0627, 43.6865]);

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



% theta(1) - average diffusion speed E-W
% theta(2) - average diffusion speed N-S
% theta(3) - contribution of terrain (b1)
n = 200;
errors = zeros(n,1);
for i = 1:n

    [A,error] = run_model(20, parameters.A, parameters.T, theory_theta, parameters.terrain, parameters.dataset_idx);
    errors(i) = calculate_error(A, parameters.dataset_idx, "average");
    disp(errors(i))
end


figure
histogram(errors, 20)
xlabel("error")
ylabel("frequency")
title("Histogram of errors")