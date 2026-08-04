clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

database_file = fullfile(repo_root, 'generated_data','sweep_grad_descent', 'filename_database.mat');
data_root = fullfile(repo_root, 'generated_data','sweep_grad_descent');
if exist(database_file, 'file') ~= 2
    database = build_filename_database_impl(data_root);
    save(database_file, 'database');
end
load(database_file, 'database');

markers = {'o', 'diamond', 'square'};
crops = {'wheat', 'rice', 'maize'};
offset = [-0.10, 0.05, 0.00];
cmap = get_plotting_colormap();
colors = [cmap(160, :); cmap(220, :); cmap(40, :)];
vmax = 110.567 / 2 / 4;
sizes = [4, 4, 4];

f = figure();
f.Position = [100 100 400 460];

subplot(5, 5, 2:10);
hold on;
legend_handles = gobjects(1, numel(crops));

for i = 1:numel(database)
    entry = database{i};
    
    for c = 1:numel(crops)
        if ~strcmp(entry.dataset, crops{c})
            continue
        end
        fit = load_fit_result(entry.file);

        if isequal(entry.layers, {'av'})
            [value, se] = get_velocity_stat(fit, 'baseline', vmax);
            y = 3 + offset(c);
        elseif isequal(entry.layers, {'sea'})
            [value, se] = get_velocity_stat(fit, 'baseline', vmax);
            y = 2 + offset(c);
        elseif numel(entry.layers) == 2 && any(strcmp(entry.layers, 'prec')) && any(strcmp(entry.layers, 'sea'))
            [value, se] = get_velocity_stat(fit, 'baseline', vmax);
            y = 1 + offset(c);
        else
            continue
        end

        errorbar(value, y, se, 'horizontal', 'Color', colors(c, :), ...
            'CapSize', 0, 'LineWidth', 1);
        h = plot(value, y, markers{c}, 'MarkerSize', sizes(c), ...
            'Color', colors(c, :), 'MarkerFaceColor', colors(c, :));
        legend_handles(c) = h;
    end
end

ylim([0 4]);
xlim([-2 8]);
xticks([0 5]);
yticks([1 2 3]);
xline(0, '--k');
legend(legend_handles, {'wheat', 'rice', 'maize'}, 'Location', 'northeast', 'Interpreter','latex');
grid on;
yticklabels({'sea and precipitation', 'sea only', 'baseline model'});
set(gca,"TickLabelInterpreter",'latex')
xlabel('average velocity (km/decade)', 'Interpreter','latex');
set(gca, 'Units', 'normalized', 'Position', [0.25 0.7 0.7 0.25])  % [left bottom width height]

subplot(5, 5, 12:25);
hold on;
layer_order = {'asym', 'csi', 'hydro', 'prec', 'tmean'};
for c = 1:numel(crops)
    for i = 1:numel(layer_order)
        entry = find_entry(database, crops{c}, {layer_order{i}, 'sea'});
        if isempty(entry)
            continue
        end
        fit = load_fit_result(entry.file);
        [value, se] = get_velocity_stat(fit, 'difference', vmax);
        y = i + offset(c);
        errorbar(value, y, se, 'horizontal', 'Color', colors(c, :), ...
            'CapSize', 0, 'LineWidth', 1);
        plot(value, y, markers{c}, 'MarkerSize', sizes(c), ...
            'Color', colors(c, :), 'MarkerFaceColor', colors(c, :));
    end
end

ylim([0 6]);
xlim([-10 10]);
xticks([-5 0 5]);
yticks(1:5);
yticklabels({'anisotropy', 'crop suitability', 'rivers', 'precipitation', 'mean temperature'});
set(gca,"TickLabelInterpreter",'latex')
xline(0, '--k');
grid on;
xlabel('velocity difference (km/decade)', 'Interpreter','latex');
set(gca, 'Units', 'normalized', 'Position', [0.25 0.1 0.7 0.5], 'FontSize', 8)  % [left bottom width height]

function entry = find_entry(database, dataset, layers)
entry = [];
for k = 1:numel(database)
    candidate = database{k};
    if strcmp(candidate.dataset, dataset) && isequal(sort(candidate.layers), sort(layers))
        entry = candidate;
        return
    end
end
end

exportgraphics(gcf,'saved_plots/estimates.pdf','ContentType','vector')