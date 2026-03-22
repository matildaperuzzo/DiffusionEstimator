clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

plot_specs = {
    'all_wheat', {}, 'Wheat - baseline'
    'cobo', {}, 'Rice - baseline'
    'maize', {}, 'Maize - baseline'
    'all_wheat', {'prec', 'sea'}, 'Wheat - sea and precipitation'
    'cobo', {'prec', 'sea'}, 'Rice - sea and precipitation'
    'maize', {'prec', 'sea'}, 'Maize - sea and precipitation'
};

f = figure();
f.Position = [100 100 800 300];
tiledlayout(2, 3, 'Padding', 'none', 'TileSpacing', 'compact');

for i = 1:size(plot_specs, 1)
    nexttile;
    fit = load_fit_result(get_recent_fit_file(repo_root, plot_specs{i, 1}, plot_specs{i, 2}));
    [x, y, colors] = get_plot_coords_from_result(fit.parameters, fit.result);
    hold on;
    for j = 1:numel(x)
        line([x(j), x(j)], [0, y(j) / 1e3], 'Color', colors(j, :), 'LineWidth', 0.5);
    end
    scatter(x, y / 1e3, 5, colors, 'filled');
    ylim([-5 5]);
    title(plot_specs{i, 3});
    grid on;
end
