clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
generated_data_dir = fullfile(repo_root, 'generated_data');

cd(repo_root);
addpath(fullfile(repo_root, 'src'));
addpath(fullfile(repo_root, 'plotting_scripts'));

layer_sets = {
    {'av'}
    {'av', 'sea'}
    {'av', 'sea', 'asym'}
    {'av', 'sea', 'hydro'}
    {'av', 'sea', 'csi'}
    {'av', 'sea', 'tmean'}
    {'av', 'sea', 'prec'}
};

for i = 1:numel(layer_sets)
    layers = layer_sets{i};
    extra_layers = layers(2:end);
    file_to_load = get_recent_fit_file(generated_data_dir, 'all_wheat', extra_layers);
    fprintf('Rerunning grad_descent for all_wheat with layers %s\n', strjoin(layers, ', '));
    fprintf('Loading %s at level 4\n', file_to_load);
    fit_model('all_wheat', layers, false, file_to_load, 4);
end
