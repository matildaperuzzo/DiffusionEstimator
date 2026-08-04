clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));
data_path = fullfile(repo_root, 'generated_data', 'sweep_grad_descent');

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
    nexttile
    fit = load_fit_result(get_recent_fit_file(data_path, plot_specs{i, 1}, plot_specs{i, 2}));
    [x, y, colors, y_se] = get_plot_coords_from_result(fit.parameters, fit.result, fit.variance_info);
    hold on;
    for j = 1:numel(x)
        line([x(j), x(j)], [0, y(j) / 1e3], 'Color', colors(j, :), 'LineWidth', 0.5);
    end

    if ~isempty(y_se)
        errorbar(x, y / 1e3, y_se / 1e3, 'vertical', ...
            'LineStyle', 'none', 'CapSize', 0, 'Color', [0 0 0], 'LineWidth', 0.35);
    end

    scatter(x, y / 1e3, 5, colors, 'filled');
    ylim([-5 5]);

    if i == 1 || i == 4
        ylabel("Error (kyears)", 'Interpreter', 'latex', 'FontSize', 8)
    else
        yticklabels([]);
    end

    if i >= 4
        xlabel("Year", 'Interpreter', 'latex', 'FontSize', 8)
    else
        xticklabels([]);
    end

    title(plot_specs{i, 3}, 'Interpreter', 'latex', 'FontSize', 10);
    set(gca, "TickLabelInterpreter", 'latex')
    grid on;
    yticks([-5, -2.5, 0, 2.5, 5])
end

set(gcf, 'Color', 'White', 'Alphamap', 0)
exportgraphics(gcf, fullfile(repo_root, 'saved_plots', 'results_error_plots.pdf'), 'ContentType', 'vector');
