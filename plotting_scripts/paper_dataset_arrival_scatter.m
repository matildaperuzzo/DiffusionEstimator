clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));
addpath(repo_root)

set(0, 'defaulttextinterpreter', 'latex');
set(0, 'DefaultFigureRenderer', 'zbuffer');

dataset_specs = {
    'all_wheat', 'Wheat'
    'cobo', 'Rice'
    'maize', 'Maize'
};

f = figure(1);
f.Position = [100 100 1200 320];
set(gcf, 'Color', 'White');
tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

for i = 1:size(dataset_specs, 1)
    dataset_name = dataset_specs{i, 1};
    title_text = dataset_specs{i, 2};

    [x, y, t] = get_dataset(dataset_name);
    parameters = data_prep(1, [1 0 0 0 0 0 0 0], x, y, t);

    ax = nexttile;
    plot_map(parameters, parameters.dataset_bp, false, [], ax);
    title(title_text, 'Interpreter', 'latex', 'FontSize', 14, 'Color', 'k');

    cb = colorbar(ax);
    cb.FontSize = 8;
    set(cb, 'TickLabelInterpreter', 'latex', 'FontSize', 8);
    ylabel(cb, 'Year of arrival, $Y_\ell$', 'FontSize', 10, 'Interpreter', 'latex', 'Rotation', -90);
end

exportgraphics(gcf, fullfile(repo_root, 'saved_plots', 'paper_dataset_arrival_scatter.pdf'), 'ContentType', 'vector');
