clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

sweep_file = fullfile('generated_data', 'cobo_sweep_2d.mat');
data_file = fullfile('generated_data', 'cobo_av_sea_100av_2026-01-06_09-18.mat');

if ~isfile(sweep_file)
    error('Missing sweep file: %s', sweep_file);
end
if ~isfile(data_file)
    error('Missing data file: %s', data_file);
end

load(sweep_file, 'all_errors', 'theta_0', 'theta_1');
load(data_file, 'parameters', 'dataset');

if strcmp(dataset, 'cobo')
    parameters.A(76,39,46) = true;
end

n_samples = 10;
random_seed = 123;
rng(random_seed);

n_theta0 = numel(theta_0);
n_theta1 = numel(theta_1);
n_grid = n_theta0 * n_theta1;
sample_linear_idx = randperm(n_grid, min(n_samples, n_grid));

results = table('Size', [numel(sample_linear_idx), 11], ...
    'VariableTypes', {'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'sample_id', 'theta0_idx', 'theta1_idx', 'theta0', ...
    'theta1', 'sweep_value', 'run_model_value', 'objective_value', ...
    'run_model_abs_diff', 'objective_abs_diff', 'objective_minus_sweep'});

for k = 1:numel(sample_linear_idx)
    linear_idx = sample_linear_idx(k);
    [theta0_idx, theta1_idx] = ind2sub(size(all_errors), linear_idx);
    theta = [theta_0(theta0_idx), theta_1(theta1_idx)];

    sweep_value = all_errors(theta0_idx, theta1_idx);
    run_model_value = run_model(parameters, theta).squared_error;
    objective_value = optimize_model(theta, parameters, 1);

    results.sample_id(k) = k;
    results.theta0_idx(k) = theta0_idx;
    results.theta1_idx(k) = theta1_idx;
    results.theta0(k) = theta(1);
    results.theta1(k) = theta(2);
    results.sweep_value(k) = sweep_value;
    results.run_model_value(k) = run_model_value;
    results.objective_value(k) = objective_value;
    results.run_model_abs_diff(k) = abs(run_model_value - sweep_value);
    results.objective_abs_diff(k) = abs(objective_value - sweep_value);
    results.objective_minus_sweep(k) = objective_value - sweep_value;
end

fprintf('\n=== sweep/objective overlap check ===\n');
fprintf('Sweep file: %s\n', sweep_file);
fprintf('Data file:  %s\n', data_file);
fprintf('Random seed: %d\n', random_seed);
fprintf('Sampled points: %d\n\n', height(results));

disp(results);

fprintf('Max |run_model - sweep|: %.12g\n', max(results.run_model_abs_diff));
fprintf('Mean |run_model - sweep|: %.12g\n', mean(results.run_model_abs_diff));
fprintf('Max |objective - sweep|: %.12g\n', max(results.objective_abs_diff));
fprintf('Mean |objective - sweep|: %.12g\n', mean(results.objective_abs_diff));

figure;
imagesc(theta_0, theta_1, all_errors');
set(gca, 'YDir', 'normal');
colorbar;
hold on;
scatter(results.theta0, results.theta1, 48, 'w', 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
for k = 1:height(results)
    text(results.theta0(k), results.theta1(k), sprintf(' %d', results.sample_id(k)), ...
        'Color', 'k', 'FontWeight', 'bold', 'FontSize', 8, ...
        'BackgroundColor', 'w', 'Margin', 0.5, 'Clipping', 'on');
end
xlabel('\theta_1');
ylabel('\theta_2');
title('Random sweep points checked against objective');
grid on;
axis tight;
hold off;
