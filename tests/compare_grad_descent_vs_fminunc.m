clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

sweep_file = fullfile(repo_root, 'generated_data', 'cobo_sweep_2d.mat');
data_file = fullfile(repo_root, 'generated_data', 'cobo_av_sea_100av_2026-01-06_09-18.mat');

plot_clim = [1.425e6, 1.45e6];
gradient_steps = fliplr(logspace(-2.8, -1.6, 4));
steps = fliplr([-0.01 0.01 0.02 0.05 0.075]);
n_starts = 4;
outside_scale = 2.0;
manual_theta0 = [];

all_errors = [];
theta_0 = [];
theta_1 = [];
if isfile(sweep_file)
    load(sweep_file, 'all_errors', 'theta_0', 'theta_1');
end
load(data_file);

if ~exist('parameters', 'var')
    error('The loaded file must contain a variable named "parameters".');
end

if exist('theta_start', 'var')
    theta_ref = theta_start(:)';
elseif exist('theta_optim', 'var')
    theta_ref = theta_optim(:)';
else
    error('No theta initializer found. Expected theta_start or theta_optim.');
end

if ~isempty(manual_theta0)
    theta_ref = manual_theta0;
end

if numel(theta_ref) ~= 2
    error('This benchmark script expects a 2-parameter theta.');
end

if ~isempty(all_errors)
    sweep_min_error = min(all_errors(:));
    [min_row, min_col] = ind2sub(size(all_errors), find(all_errors == sweep_min_error, 1, 'first'));
    sweep_min_theta = [theta_0(min_row), theta_1(min_col)];
else
    sweep_min_error = NaN;
    sweep_min_theta = [NaN, NaN];
end

if all(isfinite(sweep_min_theta))
    variance_center = sweep_min_theta;
else
    variance_center = theta_ref;
end

variance_info = compute_variance(variance_center, parameters);
ellipse_axes = reshape(variance_info.se_homo, 1, []);

if ~isempty(theta_0) && ~isempty(theta_1)
    sweep_span = min([max(theta_0) - min(theta_0), max(theta_1) - min(theta_1)]);
else
    sweep_span = 1;
end
ellipse_axes = max(ellipse_axes, 0.02 * sweep_span);
start_axes = outside_scale * ellipse_axes;
start_points = sample_start_points_on_ellipse(variance_center, start_axes, n_starts);

fminunc_options = optimoptions('fminunc', ...
    'Display', 'off', ...
    'Algorithm', 'trust-region', ...
    'HessianFcn', 'objective', ...
    'SpecifyObjectiveGradient', true, ...
    'StepTolerance', 5e-3, ...
    'FiniteDifferenceStepSize', 0.001, ...
    'FunctionTolerance', 1e-5, ...
    'OptimalityTolerance', 2e-6, ...
    'MaxFunctionEvaluations', 10000, ...
    'MaxIterations', 10000, ...
    'UseParallel', false);

gd_results = cell(n_starts, 1);
fminunc_results = cell(n_starts, 1);

use_parallel = has_parallel_toolbox();
if use_parallel
    parfor start_idx = 1:n_starts
        gd_results{start_idx} = run_custom_descent(start_points(start_idx,:), parameters, gradient_steps, steps);
        fminunc_results{start_idx} = run_fminunc_descent(start_points(start_idx,:), parameters, fminunc_options);
    end
else
    for start_idx = 1:n_starts
        gd_results{start_idx} = run_custom_descent(start_points(start_idx,:), parameters, gradient_steps, steps);
        fminunc_results{start_idx} = run_fminunc_descent(start_points(start_idx,:), parameters, fminunc_options);
    end
end

if isempty(all_errors)
    sweep_min_error = min(cellfun(@(r) r.final_error, [gd_results; fminunc_results]));
    sweep_min_theta = [NaN, NaN];
end

gd_summary = build_summary_table(gd_results, start_points, sweep_min_error, 'custom_gd');
fminunc_summary = build_summary_table(fminunc_results, start_points, sweep_min_error, 'fminunc');
summary_table = [gd_summary; fminunc_summary];

fprintf('\n=== optimizer benchmark summary ===\n');
fprintf('Reference theta: %s\n', mat2str(theta_ref, 6));
fprintf('Variance center: %s\n', mat2str(variance_center, 6));
fprintf('Variance ellipse axes: %s\n', mat2str(ellipse_axes, 6));
fprintf('Start ellipse axes: %s\n', mat2str(start_axes, 6));
fprintf('Used parallel: %d\n', use_parallel);
fprintf('Sweep minimum error: %.12g\n', sweep_min_error);
if all(isfinite(sweep_min_theta))
    fprintf('Sweep minimum theta: %s\n', mat2str(sweep_min_theta, 6));
end
fprintf('Custom GD mean runtime: %.3f s\n', mean(gd_summary.runtime_sec));
fprintf('fminunc mean runtime: %.3f s\n', mean(fminunc_summary.runtime_sec));
fprintf('Custom GD mean final error gap: %.12g\n', mean(gd_summary.error_gap_to_sweep_min));
fprintf('fminunc mean final error gap: %.12g\n\n', mean(fminunc_summary.error_gap_to_sweep_min));
disp(summary_table);

plot_optimizer_paths(all_errors, theta_0, theta_1, plot_clim, theta_ref, variance_center, ellipse_axes, ...
    start_points, gd_results, fminunc_results, sweep_min_theta);

function result = run_custom_descent(theta0, parameters, gradient_steps, steps)
    tic;
    [theta_best, best_error, history] = sweep_gradient_descent(theta0, parameters, gradient_steps, steps);
    elapsed = toc;

    result = struct();
    result.theta_final = theta_best;
    result.final_error = best_error;
    result.runtime_sec = elapsed;
    result.path = [theta0(:)'; history.new_theta];
    result.n_steps = size(history.new_theta, 1);
    result.history = history;
end

function result = run_fminunc_descent(theta0, parameters, options)
    objective_function = @(theta) optimize_model(theta, parameters, 1e5);
    path = theta0(:)';
    fvals = objective_function(theta0);

    function stop = record_iteration(x, optimValues, state)
        stop = false;
        if strcmp(state, 'iter')
            path(end + 1, :) = x(:)';
            fvals(end + 1, 1) = optimValues.fval;
        end
    end

    options_local = optimoptions(options, 'OutputFcn', @record_iteration);

    tic;
    [theta_final, fval, exitflag, output] = fminunc(objective_function, theta0, options_local);
    elapsed = toc;

    if isempty(path) || any(path(end,:) ~= theta_final(:)')
        path(end + 1, :) = theta_final(:)';
        fvals(end + 1, 1) = fval;
    end

    result = struct();
    result.theta_final = theta_final(:)';
    result.final_error = fval;
    result.runtime_sec = elapsed;
    result.path = path;
    result.path_values = fvals;
    result.exitflag = exitflag;
    result.output = output;
    result.n_steps = size(path, 1) - 1;
end

function summary = build_summary_table(results, start_points, sweep_min_error, method_name)
    n = numel(results);
    summary = table('Size', [n, 8], ...
        'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'method', 'start_id', 'start_theta_1', 'start_theta_2', ...
        'final_theta_1', 'final_theta_2', 'final_error', 'runtime_sec'});

    for idx = 1:n
        res = results{idx};
        summary.method(idx) = string(method_name);
        summary.start_id(idx) = idx;
        summary.start_theta_1(idx) = start_points(idx, 1);
        summary.start_theta_2(idx) = start_points(idx, 2);
        summary.final_theta_1(idx) = res.theta_final(1);
        summary.final_theta_2(idx) = res.theta_final(2);
        summary.final_error(idx) = res.final_error;
        summary.runtime_sec(idx) = res.runtime_sec;
    end

    summary.error_gap_to_sweep_min = summary.final_error - sweep_min_error;
end

function plot_optimizer_paths(all_errors, theta_0, theta_1, plot_clim, theta_ref, variance_center, ellipse_axes, ...
    start_points, gd_results, fminunc_results, sweep_min_theta)
    figure;
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot_method_panel(all_errors, theta_0, theta_1, plot_clim, theta_ref, variance_center, ellipse_axes, ...
        start_points, gd_results, sweep_min_theta, 'Custom gradient descent');

    nexttile;
    plot_method_panel(all_errors, theta_0, theta_1, plot_clim, theta_ref, variance_center, ellipse_axes, ...
        start_points, fminunc_results, sweep_min_theta, 'fminunc');

    sgtitle('Optimizer comparison from variance-ellipse start points');
end

function plot_method_panel(all_errors, theta_0, theta_1, plot_clim, theta_ref, variance_center, ellipse_axes, ...
    start_points, results, sweep_min_theta, panel_title)
    hold on;
    if ~isempty(all_errors) && ~isempty(theta_0) && ~isempty(theta_1)
        imagesc(theta_0, theta_1, all_errors');
        set(gca, 'YDir', 'normal');
        if ~isempty(plot_clim)
            clim(plot_clim);
        end
        colorbar;
    end

    ellipse_angles = linspace(0, 2 * pi, 300);
    ellipse_x = variance_center(1) + ellipse_axes(1) * cos(ellipse_angles);
    ellipse_y = variance_center(2) + ellipse_axes(2) * sin(ellipse_angles);
    plot(ellipse_x, ellipse_y, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Variance ellipse');

    path_colors = lines(numel(results));
    for idx = 1:numel(results)
        res = results{idx};
        color = path_colors(idx,:);

        plot(start_points(idx,1), start_points(idx,2), 'o', ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', 'k', 'MarkerSize', 7, ...
            'DisplayName', sprintf('Start %d', idx));

        if size(res.path, 1) > 1
            plot(res.path(:,1), res.path(:,2), '-', 'Color', color, ...
                'LineWidth', 1.4, 'HandleVisibility', 'off');

            for step_idx = 2:size(res.path, 1)
                old_theta = res.path(step_idx - 1, :);
                new_theta = res.path(step_idx, :);
                delta = new_theta - old_theta;
                quiver(old_theta(1), old_theta(2), delta(1), delta(2), 0, ...
                    'Color', color, 'LineWidth', 0.9, 'MaxHeadSize', 0.4, ...
                    'HandleVisibility', 'off');
            end
        end

        plot(res.theta_final(1), res.theta_final(2), 's', ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', 'k', 'MarkerSize', 6, ...
            'HandleVisibility', 'off');
    end

    plot(theta_ref(1), theta_ref(2), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8, ...
        'DisplayName', 'Reference theta');
    if all(isfinite(sweep_min_theta))
        plot(sweep_min_theta(1), sweep_min_theta(2), 'kp', 'MarkerFaceColor', 'y', ...
            'MarkerSize', 12, 'DisplayName', 'Sweep minimum');
    end

    xlabel('\theta_1');
    ylabel('\theta_2');
    title(panel_title);
    grid on;
    axis tight;
    hold off;
end

function start_points = sample_start_points_on_ellipse(center, axes_lengths, n_points)
    min_gap = 0.6 * (2 * pi / n_points);
    max_tries = 5000;
    angles = zeros(n_points, 1);

    for point_idx = 1:n_points
        accepted = false;
        for try_idx = 1:max_tries
            candidate = 2 * pi * rand();
            if point_idx == 1
                accepted = true;
            else
                gaps = abs(wrap_to_pi_local(candidate - angles(1:point_idx - 1)));
                accepted = all(gaps >= min_gap);
            end

            if accepted
                angles(point_idx) = candidate;
                break;
            end
        end

        if ~accepted
            angles = linspace(0, 2 * pi, n_points + 1)';
            angles(end) = [];
            break;
        end
    end

    angles = sort(angles);
    start_points = center + [axes_lengths(1) * cos(angles), axes_lengths(2) * sin(angles)];
end

function wrapped = wrap_to_pi_local(values)
    wrapped = mod(values + pi, 2 * pi) - pi;
end

function [theta, value, history] = sweep_gradient_descent(theta0, parameters, gradient_steps, steps)
    objective_function = @(theta) optimize_model(theta, parameters, 1);
    theta = theta0(:)';
    value = objective_function(theta);

    gradient_steps = sort(reshape(gradient_steps, 1, []), 'descend');
    steps = sort(reshape(steps, 1, []), 'descend');

    history = struct();
    history.old_theta = zeros(0, numel(theta));
    history.new_theta = zeros(0, numel(theta));
    history.gradient_step = zeros(0, 1);
    history.step_size = zeros(0, 1);
    history.values = value;

    for grad_idx = 1:numel(gradient_steps)
        grad_step = gradient_steps(grad_idx);

        while true
            grad = calculateGradient(objective_function, theta, grad_step, 1);
            grad = grad(:)';
            grad_norm = norm(grad);

            if ~isfinite(grad_norm) || grad_norm == 0
                break;
            end

            direction = -grad / grad_norm;
            found_improvement = false;

            for step_idx = 1:numel(steps)
                step_size = steps(step_idx);
                candidate_theta = theta + step_size * direction;
                candidate_value = objective_function(candidate_theta);

                if candidate_value < value
                    history.old_theta(end + 1, :) = theta;
                    history.new_theta(end + 1, :) = candidate_theta;
                    history.gradient_step(end + 1, 1) = grad_step;
                    history.step_size(end + 1, 1) = step_size;
                    history.values(end + 1, 1) = candidate_value;

                    theta = candidate_theta;
                    value = candidate_value;
                    found_improvement = true;
                    break;
                end
            end

            if ~found_improvement
                break;
            end
        end
    end
end

function tf = has_parallel_toolbox()
    tf = ~isempty(ver('parallel')) && license('test', 'Distrib_Computing_Toolbox');
end
