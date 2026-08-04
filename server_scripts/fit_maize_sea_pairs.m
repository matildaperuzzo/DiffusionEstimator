clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
cd(repo_root);
addpath(fullfile(repo_root, 'src'));

layer_pairs = {
    % {'av', 'asym', 'sea'}
    % {'av', 'csi', 'sea'}
    % {'av', 'hydro', 'sea'}
    % {'av', 'prec', 'sea'}
    {'av', 'tmean', 'sea'}
};

for i = 1:size(layer_pairs, 1)
    layers = layer_pairs{i};
    fprintf('Running fit_model for maize with layers %s\n', strjoin(layers, ', '));
    fit_model('maize', layers);
end
