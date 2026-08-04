clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

set(0, 'defaulttextinterpreter', 'latex');

% --- Load Monte Carlo database (sweep_grad_descent) ---
mc_db_file = fullfile(repo_root, 'generated_data', 'sweep_grad_descent', 'filename_database.mat');
if exist(mc_db_file, 'file') ~= 2
    mc_database = build_filename_database_impl(fullfile(repo_root, 'generated_data', 'sweep_grad_descent'), false);
    save(mc_db_file, 'mc_database');
else
    loaded = load(mc_db_file);
    mc_database = loaded.database;
end

target_layers = {
    {'av'}
    {'sea'}
    {'csi', 'sea'}
    {'hydro', 'sea'}
    {'prec', 'sea'}
    {'tmean', 'sea'}
};

display_names = {
    'Baseline'
    'Sea only'
    'Crop suitability'
    'River size'
    'Precipitation'
    'Mean temperature'
};

kpp_dir = fullfile(repo_root, 'generated_data');

[~, yr_errors_mc, yr_errorbar_mc] = collect_errors_mc(mc_database, 'maize', target_layers);
[~, yr_errors_kpp, yr_errorbar_kpp] = collect_errors_kpp(kpp_dir, 'maize', target_layers);

% Order by MC error descending
[~, order] = sort(yr_errors_mc, 'descend');
ordered_labels = display_names(order);

f = figure(1);
clf;
f.Position = [100 100 600 300];
hold on;

n = numel(target_layers);
y_pos = (1:n)';
bar_height = 0.35;

cmap = slanCM('romao');
color_mc  = cmap(round(0.25 * size(cmap, 1)), :);
color_kpp = cmap(round(0.70 * size(cmap, 1)), :);

% MC bars (upper half of each group)
bh_mc = barh(y_pos + bar_height/2, yr_errors_mc(order) / 1e3, bar_height, ...
    'FaceColor', color_mc, 'EdgeAlpha', 0, 'DisplayName', 'Monte Carlo');

% KPP bars (lower half of each group)
bh_kpp = barh(y_pos - bar_height/2, yr_errors_kpp(order) / 1e3, bar_height, ...
    'FaceColor', color_kpp, 'EdgeAlpha', 0, 'DisplayName', 'KPP');

% Error bars
errorbar(yr_errors_mc(order)  / 1e3, y_pos + bar_height/2, yr_errorbar_mc(order)  / 1e3, ...
    'horizontal', 'LineStyle', 'none', 'CapSize', 4, 'Color', 'k', 'LineWidth', 0.75);
errorbar(yr_errors_kpp(order) / 1e3, y_pos - bar_height/2, yr_errorbar_kpp(order) / 1e3, ...
    'horizontal', 'LineStyle', 'none', 'CapSize', 4, 'Color', 'k', 'LineWidth', 0.75);

% Layer labels on y-axis
yticks(1:n);
yticklabels(fliplr(ordered_labels));  % barh orders bottom-up so flip
set(gca, 'YDir', 'reverse');

legend([bh_mc, bh_kpp], {'Monte Carlo', 'KPP'}, ...
    'Interpreter', 'latex', 'FontSize', 8, 'Location', 'southeast');

xlabel('Average error (kyears)', 'FontSize', 8, 'Interpreter', 'latex', 'Color', 'k');
title('Maize: Monte Carlo vs.\ KPP', 'Interpreter', 'latex', 'Color', 'k');
xlim([0, 1.8]);
set(gca, 'TickLabelInterpreter', 'latex');
set(gca, 'XColor', [0 0 0]);
set(gca, 'YColor', [0 0 0]);
set(gca, 'Color', 'White');
grid on;

set(gcf, 'Color', 'White');

exportgraphics(gcf, fullfile(repo_root, 'saved_plots', 'mc_vs_kpp_bar_chart.pdf'), 'ContentType', 'vector');

% -------------------------------------------------------------------------

function [sq_errors, yr_errors, yr_errorbar] = collect_errors_mc(database, dataset, target_layers)
sq_errors  = NaN(1, numel(target_layers));
yr_errors  = NaN(1, numel(target_layers));
yr_errorbar = NaN(1, numel(target_layers));

for i = 1:numel(target_layers)
    entry = find_db_entry(database, dataset, target_layers{i});
    if isempty(entry)
        warning('MC: no entry for dataset=%s layers=%s', dataset, strjoin(target_layers{i}, ','));
        continue
    end
    fit = load_fit_result(entry.file);
    sq_errors(i)   = fit.result.squared_error;
    yr_errors(i)   = sqrt(fit.result.squared_error);
    yr_errorbar(i) = rmse_se_total(fit.result.errors);
end
end

function [sq_errors, yr_errors, yr_errorbar] = collect_errors_kpp(kpp_dir, crop, target_layers)
sq_errors  = NaN(1, numel(target_layers));
yr_errors  = NaN(1, numel(target_layers));
yr_errorbar = NaN(1, numel(target_layers));

crop_prefix_map = struct('wheat', 'all_wheat', 'rice', 'cobo', 'maize', 'maize');
crop_prefix = crop_prefix_map.(crop);

for i = 1:numel(target_layers)
    layers = target_layers{i};
    file = find_kpp_file(kpp_dir, crop_prefix, layers);
    if isempty(file)
        warning('KPP: no file for crop=%s layers=%s', crop, strjoin(layers, ','));
        continue
    end
    fit = load_fit_result(file);
    sq_errors(i)   = fit.result.squared_error;
    yr_errors(i)   = sqrt(fit.result.squared_error);
    yr_errorbar(i) = rmse_se_total(fit.result.errors);
end
end

function file = find_kpp_file(kpp_dir, crop_prefix, layers)
% KPP files follow the pattern: <crop>_av[_layer1_layer2...]_ 100 av_ kpp_*.mat
file = '';
if isequal(layers, sort({'av'}))
    pattern = sprintf('%s_av_ 100 av_ kpp_*.mat', crop_prefix);
else
    extra = layers(~strcmp(layers, 'av'));
    extra_sorted = sort(extra);
    layer_str = strjoin(extra, '_');
    pattern = sprintf('%s_av_%s_ 100 av_ kpp_*.mat', crop_prefix, layer_str);
end

files = dir(fullfile(kpp_dir, pattern));
if isempty(files)
    return
end
[~, idx] = max([files.datenum]);
file = fullfile(files(idx).folder, files(idx).name);
end

function entry = find_db_entry(database, dataset, layers)
entry = [];
for k = 1:numel(database)
    candidate = database{k};
    if strcmp(candidate.dataset, dataset) && isequal(sort(candidate.layers), sort(layers))
        entry = candidate;
        return
    end
end
end

function se = rmse_se_total(e)
e = e(:);
L = length(e);
q = e.^2;
Qstar = mean(q);
Omega_hat = mean((q - Qstar).^2);
se = sqrt(Omega_hat / (4 * Qstar * L));
end
