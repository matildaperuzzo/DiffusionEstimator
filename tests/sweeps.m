clear
clc

% figure

% Add the directory containing run_model.m to the MATLAB path
addpath('src');
rng(12) % set random seed

theory_theta = [0.3, 0.3, 0.0];
theory_av = theory_theta(1);
theory_r = theory_theta(2)/theory_theta(1);
theory_terrain = theory_theta(3);

% choose whether to load pinhasi dataset or create a dataset
% parameters = data_prep();
parameters = create_dataset(theory_theta, 20, [53.0627, 43.6865]);

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

%%

% theta(1) - average diffusion speed E-W
% theta(2) - average diffusion speed N-S
% theta(3) - contribution of terrain (b1)

av_theta = linspace(0.2,0.8,101);
r_theta = logspace(-1,1,100);
terrain_theta = theory_terrain;
all_errors = zeros(length(av_theta),length(r_theta),length(terrain_theta));
 
for t = 1:length(terrain_theta)
    for y = 1:length(r_theta)
        for x = 1:length(av_theta)
            theta = [av_theta(x), av_theta(x)*r_theta(y), terrain_theta(t)];
            [A, error, times] = run_model(20, parameters.A, parameters.T, theta, parameters.terrain, parameters.dataset_idx,parameters.U);
            all_errors(x,y,t) = calculate_error(parameters.dataset_idx, times, "absolute");
            disp(theta);
            disp(all_errors(x,y,t));

        end
    end
end

save("sweep_results_ratio_no_chatter_20_avs.mat","all_errors","av_theta","r_theta","terrain_theta",'-mat')
% disp("Done!")