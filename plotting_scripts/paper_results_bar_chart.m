clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

set(0, 'defaulttextinterpreter', 'latex');

database_file = fullfile(repo_root, 'generated_data', 'sweep_grad_descent', 'filename_database.mat');
if exist(database_file, 'file') ~= 2
    database = build_filename_database_impl(fullfile(repo_root, 'generated_data'), false);
    save(database_file, 'database');
end
load(database_file, 'database');

target_layers = {
    {'av'}
    {'sea'}
    % {'asym', 'sea'}
    {'csi', 'sea'}
    {'hydro', 'sea'}
    {'prec', 'sea'}
    {'tmean', 'sea'}
};

display_names = {
    'Baseline'
    'Sea only'
    'Anisotropy'
    'Crop suitability'
    'River size'
    'Precipitation'
    'Mean temperature'
};

[sq_errors_w, yr_errors_w, yr_errorbar_w] = collect_errors(database, 'wheat', target_layers);
[~, yr_errors_r, yr_errorbar_r] = collect_errors(database, 'rice', target_layers);
[~, yr_errors_m, yr_errorbar_m] = collect_errors(database, 'maize', target_layers);

[~, w_idx] = sort(sq_errors_w, 'descend');
ordered_labels = display_names(w_idx);

f = figure(1);
f.Position = [100 100 800 180];
tiledlayout(1, 3, 'Padding', 'none', 'TileSpacing', 'compact');

cmap = slanCM('romao');
x_errorbar = [-2.5 -1.5 -0.5 0.5 1.5 2.5 ] .* 0.135;

for p = 1:3
    nexttile
    hold on

    switch p
        case 1
            title_text = "Wheat";
            plot_errors = yr_errors_w;
            plot_errorbar = yr_errorbar_w;
        case 2
            title_text = "Rice";
            plot_errors = yr_errors_r;
            plot_errorbar = yr_errorbar_r;
        otherwise
            title_text = "Maize";
            plot_errors = yr_errors_m;
            plot_errorbar = yr_errorbar_m;
    end

    b = barh([0], fliplr(plot_errors(w_idx)) / 1e3, 0.95);
    errorbar(fliplr(plot_errors(w_idx)) / 1e3, x_errorbar, fliplr(plot_errorbar(w_idx)) / 1e3, ...
        'horizontal', 'LineStyle', 'none', 'CapSize', 4, 'Color', 'k', 'LineWidth', 0.75);

    yticks([]);
    ylabel({'Geographical layer'}, 'Interpreter', 'latex', 'FontSize', 8, 'Rotation', 90, 'Color', 'k');
    title(title_text, 'Interpreter', 'latex', 'Color', 'k');

    for k = 1:numel(plot_errors)
        b(k).FaceColor = cmap(int16(k * length(cmap) / (numel(plot_errors) + 1)), :);
        b(k).EdgeAlpha = 0;
        ypos = b(k).XEndPoints;
        text(0.02 * ones(size(ypos)), ypos, ordered_labels{numel(plot_errors) - k + 1}, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 8, ...
            'Interpreter', 'latex', ...
            'Rotation', 0, ...
            'Color', 'k');
    end

    xlabel("Average error (kyears)", 'FontSize', 8, 'Interpreter', 'latex', 'Color', 'k');
    xlim([0, 1.8]);
    set(gca, 'TickLabelInterpreter', 'latex', 'Color', 'k');
    set(gca, 'XColor', [0, 0, 0]);
    set(gca, 'YColor', [0, 0, 0]);
    set(gca, 'Color', 'White', 'Alphamap', 1);
    grid on
end

set(gcf, 'Color', 'White', 'Alphamap', 1);

exportgraphics(gcf, fullfile(repo_root, 'saved_plots', 'results_horizontal_bar_chart.pdf'), 'ContentType', 'vector');

function [sq_errors, yr_errors, yr_errorbar] = collect_errors(database, dataset, target_layers)
sq_errors = NaN(1, numel(target_layers));
yr_errors = NaN(1, numel(target_layers));
yr_errorbar = NaN(1, numel(target_layers));

for i = 1:numel(target_layers)
    entry = find_entry(database, dataset, target_layers{i});
    fit = load_fit_result(entry.file);

    sq_errors(i) = fit.result.squared_error;
    yr_errors(i) = sqrt(fit.result.squared_error);
    % yr_errorbar(i) = get_error_se_from_variance(fit);
    yr_errorbar(i) = rmse_se_total(fit.result.errors) + get_error_se_from_variance(fit);
end
end

function entry = find_entry(database, dataset, layers)
entry = [];
for k = 1:numel(database)
    candidate = database{k};
    if strcmp(candidate.dataset, dataset) && isequal(sort(candidate.layers), sort(layers))
        entry = candidate;
        return
    end
end

error('No database entry found for dataset %s and layers %s.', dataset, strjoin(layers, ', '));
end

function se = get_error_se_from_variance(fit)
if ~isfield(fit, 'variance_info') || isempty(fit.variance_info) || ...
        ~isfield(fit.variance_info, 'V_iid') || isempty(fit.variance_info.V_iid)
    se = NaN;
    return
end

theta = fit.theta_optim(:);
cov_theta = fit.variance_info.V_iid / size(fit.parameters.dataset_idx, 1);
metric = @(th) sqrt(run_model(fit.parameters, th(:)').squared_error);
window_size = 0.1;
[grad, hessian] = calculate_gradient_fit(metric, theta, [], window_size);
grad = grad(:);
hessian = squeeze(hessian);

first_order_var = grad' * cov_theta * grad;
second_order_var = 0.5 * trace(hessian * cov_theta * hessian * cov_theta);
se = sqrt(max(first_order_var + second_order_var, 0));
end

function se = rmse_se_total(e)
% Computes analytical SE of RMSE based on total sampling variability
%
% Input:
%   e : vector of residuals (errors), size Lx1 or 1xL
%
% Output:
%   se : standard error of RMSE

    e = e(:);              % ensure column vector
    L = length(e);

    q = e.^2;              % squared errors
    Qstar = mean(q);       % empirical MSE

    Omega_hat = mean((q - Qstar).^2);   % variance of q (not unbiased; matches formula)

    se = sqrt(Omega_hat / (4 * Qstar * L));
end