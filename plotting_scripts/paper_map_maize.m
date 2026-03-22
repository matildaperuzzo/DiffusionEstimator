clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

fit = load_fit_result(get_recent_fit_file(repo_root, 'maize', {'prec', 'sea'}));
simulation = (fit.parameters.end_time - mean(fit.result.A, 3) * ...
    (fit.parameters.end_time - fit.parameters.start_time)) / 1000;

figure();
plot_map_flat(fit.parameters, fit.parameters.dataset_bp / 1000, false, simulation);
colormap(get_plotting_colormap());
title('Maize - sea and precipitation');
