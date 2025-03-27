clear
clc

% figure

% Add the directory containing run_model.m to the MATLAB path
addpath('src');
rng(12) % set random seed
dataset = 'cobo';
[x,y,t] = get_dataset(dataset);
active_layers = [  1   0   0   0   0   1   0   0   0  ];
parameters = data_prep(50, active_layers, x, y, t);

%%
if strcmp(dataset,'cobo')
    parameters.A(76,39,46) = true;
end
ranges = [[-2, -0.]; [-1.0,1.0]];
n_points = 101;
[theta_min, on_edge, min_error, errors] = sweep(ranges, n_points, 0, parameters);
theta_0 = linspace(ranges(1,1), ranges(1,2), n_points);
theta_1 = linspace(ranges(2,1), ranges(2,2), n_points);
all_errors = reshape(errors, [n_points,n_points]);
% 
save("cobo_av_tmean.mat","all_errors","theta_0","theta_1",'-mat')
disp("Done!")

