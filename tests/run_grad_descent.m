clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

sweep_file = fullfile(repo_root, 'generated_data', 'cobo_sweep_2d.mat');
data_file = fullfile(repo_root, 'generated_data', 'cobo_av_sea_100av_2026-01-06_09-18.mat');

if ~isfile(data_file)
    error('Missing data file: %s', data_file);
end

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
    theta0_loaded = theta_start(:)';
elseif exist('theta_optim', 'var')
    theta0_loaded = theta_optim(:)';
else
    error('No theta initializer found. Expected "theta_start" or "theta_optim" in MAT file.');
end

manual_theta0 = [];
if ~isempty(manual_theta0)
    theta0 = manual_theta0;
else
    theta0 = theta0_loaded;
end
debug_mode = true;
plot_clim = [1.425e6, 1.45e6];

gradient_steps = fliplr(logspace(-2.8, -1.6, 6));
steps = fliplr([-0.01 0.01 0.02 0.03 0.05 0.075 0.15]);

[theta_best, best_error, history] = sweep_gradient_descent( ...
    theta0, parameters, gradient_steps, steps, debug_mode);

figure;
hold on;

if exist('all_errors', 'var') && exist('theta_0', 'var') && exist('theta_1', 'var')
    imagesc(theta_0, theta_1, all_errors');
    set(gca, 'YDir', 'normal');
    if ~isempty(plot_clim)
        clim(plot_clim);
    end
    colorbar;
end

plot(theta0(1), theta0(2), 'ko', 'MarkerFaceColor', 'w', 'DisplayName', 'Start');
plot(theta_best(1), theta_best(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, ...
    'DisplayName', 'Final');

n_moves = size(history.old_theta, 1);
path_color_limits = plot_clim;
if isempty(path_color_limits)
    path_color_limits = [min(history.values), max(history.values)];
    if path_color_limits(1) == path_color_limits(2)
        path_color_limits(2) = path_color_limits(1) + 1;
    end
end
path_cmap = colormap(gca);
for k = 1:n_moves
    old_theta = history.old_theta(k,:);
    new_theta = history.new_theta(k,:);
    delta = new_theta - old_theta;
    point_color = map_values_to_colors(history.values(k + 1), path_cmap, path_color_limits);
    arrow_color = 0.65 * point_color + 0.35 * [1 1 1];
    scatter(new_theta(1), new_theta(2), 42, 'MarkerFaceColor', point_color, ...
        'MarkerEdgeColor', 'k', 'LineWidth', 0.75, 'HandleVisibility', 'off');
    quiver(old_theta(1), old_theta(2), delta(1), delta(2), 0, ...
        'Color', arrow_color, 'LineWidth', 1.5, 'MaxHeadSize', 0.5, ...
        'HandleVisibility', 'off');
end

xlabel('\theta_1');
ylabel('\theta_2');
title('Gradient descent path with nested step sweeps');
grid on;
axis tight;
hold off;

if debug_mode
    plot_debug_attempts(theta0, theta_best, history, all_errors, theta_0, theta_1, plot_clim);
end

fprintf('\n=== gradient descent summary ===\n');
fprintf('Initial theta: %s\n', mat2str(theta0, 6));
fprintf('Final theta:   %s\n', mat2str(theta_best, 6));
fprintf('Initial error: %.12g\n', history.values(1));
fprintf('Final error:   %.12g\n', best_error);
fprintf('Accepted moves: %d\n', n_moves);

if n_moves > 0
    summary_table = table((1:n_moves)', history.gradient_step(:), history.step_size(:), ...
        history.values(2:end), 'VariableNames', ...
        {'move_id', 'gradient_step', 'step_size', 'objective_value'});
    disp(summary_table);
else
    disp('No improving step was found for any gradient-step / step-size combination.');
end

function [theta, value, history] = sweep_gradient_descent(theta0, parameters, gradient_steps, steps, debug_mode)
    objective_function = @(theta) optimize_model(theta, parameters, 1);
    objective_function_mean = @(theta) optimize_model(theta, parameters, 1);
    theta = theta0(:)';
    value = objective_function(theta);
    move_count = 0;
    iteration_count = 0;

    gradient_steps = sort(reshape(gradient_steps, 1, []), 'descend');
    steps = sort(reshape(steps, 1, []), 'descend');

    history = struct();
    history.old_theta = zeros(0, numel(theta));
    history.new_theta = zeros(0, numel(theta));
    history.gradient_step = zeros(0, 1);
    history.step_size = zeros(0, 1);
    history.values = value;
    history.iteration = zeros(0, 1);
    history.attempt_iteration = zeros(0, 1);
    history.attempt_old_theta = zeros(0, numel(theta));
    history.attempt_new_theta = zeros(0, numel(theta));
    history.attempt_gradient = zeros(0, numel(theta));
    history.attempt_gradient_step = zeros(0, 1);
    history.attempt_step_size = zeros(0, 1);
    history.attempt_old_value = zeros(0, 1);
    history.attempt_new_value = zeros(0, 1);
    history.attempt_accepted = false(0, 1);

    fprintf('\nStarting gradient descent\n');
    fprintf('Initial theta: %s\n', mat2str(theta, 6));
    fprintf('Initial objective: %.12g\n', value);
    fprintf('Gradient steps: %s\n', mat2str(gradient_steps, 6));
    fprintf('Line-search steps: %s\n\n', mat2str(steps, 6));

    for grad_idx = 1:numel(gradient_steps)
        grad_step = gradient_steps(grad_idx);
        fprintf('Outer loop %d/%d: gradient step = %.6g\n', ...
            grad_idx, numel(gradient_steps), grad_step);

        while true
            iteration_count = iteration_count + 1;
            fprintf('  Current theta = %s, objective = %.12g\n', mat2str(theta, 6), value);
            fprintf('  Iteration %d\n', iteration_count);
            fprintf('  Estimating gradient with epsilon = %.6g\n', grad_step);
            grad = calculateGradient(objective_function_mean, theta, grad_step, 1);
            grad = grad(:)';
            grad_norm = norm(grad);
            fprintf('  Gradient = %s, norm = %.12g\n', mat2str(grad, 6), grad_norm);

            if ~isfinite(grad_norm) || grad_norm == 0
                fprintf('  Gradient norm is zero or non-finite. Moving to next gradient step.\n');
                break;
            end

            direction = - grad / grad_norm;
            fprintf('  Descent direction = %s\n', mat2str(direction, 6));
            found_improvement = false;

            for step_idx = 1:numel(steps)
                step_size = steps(step_idx);
                candidate_theta = theta + step_size * direction;
                candidate_value = objective_function(candidate_theta);
                fprintf(['    Trial %d/%d: step = %.6g, candidate theta = %s, ' ...
                    'objective = %.12g'], step_idx, numel(steps), step_size, ...
                    mat2str(candidate_theta, 6), candidate_value);

                if debug_mode
                    history.attempt_iteration(end + 1, 1) = iteration_count;
                    history.attempt_old_theta(end + 1, :) = theta;
                    history.attempt_new_theta(end + 1, :) = candidate_theta;
                    history.attempt_gradient(end + 1, :) = grad;
                    history.attempt_gradient_step(end + 1, 1) = grad_step;
                    history.attempt_step_size(end + 1, 1) = step_size;
                    history.attempt_old_value(end + 1, 1) = value;
                    history.attempt_new_value(end + 1, 1) = candidate_value;
                    history.attempt_accepted(end + 1, 1) = false;
                end

                if candidate_value < value
                    fprintf(' -> accepted\n');
                    history.old_theta(end + 1, :) = theta;
                    history.new_theta(end + 1, :) = candidate_theta;
                    history.gradient_step(end + 1, 1) = grad_step;
                    history.step_size(end + 1, 1) = step_size;
                    history.values(end + 1, 1) = candidate_value;
                    history.iteration(end + 1, 1) = iteration_count;

                    if debug_mode
                        history.attempt_accepted(end, 1) = true;
                    end

                    move_count = move_count + 1;
                    theta = candidate_theta;
                    value = candidate_value;
                    found_improvement = true;
                    fprintf('    Accepted move %d. New objective = %.12g\n', move_count, value);
                    break;
                else
                    fprintf(' -> rejected\n');
                end
            end

            if ~found_improvement
                fprintf('  No improving line-search step found for gradient step %.6g\n', grad_step);
                break;
            end
        end

        fprintf('Completed outer loop %d/%d. Best objective so far = %.12g\n\n', ...
            grad_idx, numel(gradient_steps), value);
    end

    fprintf('Gradient descent finished after %d accepted moves.\n', move_count);
end

function plot_debug_attempts(theta0, theta_best, history, all_errors, theta_0, theta_1, plot_clim)
    figure;
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    hold on;
    color_limits = [];
    if nargin >= 4 && ~isempty(all_errors) && ~isempty(theta_0) && ~isempty(theta_1)
        imagesc(theta_0, theta_1, all_errors');
        set(gca, 'YDir', 'normal');
        if nargin >= 7 && ~isempty(plot_clim)
            clim(plot_clim);
        end
        colorbar;
        color_limits = clim;
    end
    plot(theta0(1), theta0(2), 'ko', 'MarkerFaceColor', 'w', 'DisplayName', 'Start');
    plot(theta_best(1), theta_best(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, ...
        'DisplayName', 'Final');
    plot_attempt_layers(history, false, color_limits);
    xlabel('\theta_1');
    ylabel('\theta_2');
    title('All attempts');
    grid on;
    axis tight;
    hold off;

    nexttile;
    hold on;
    if nargin >= 4 && ~isempty(all_errors) && ~isempty(theta_0) && ~isempty(theta_1)
        imagesc(theta_0, theta_1, all_errors');
        set(gca, 'YDir', 'normal');
        colorbar;
        if nargin >= 7 && ~isempty(plot_clim)
            clim(plot_clim);
            color_limits = plot_clim;
        elseif ~isempty(color_limits)
            clim(color_limits);
        else
            color_limits = clim;
        end
    end
    plot(theta0(1), theta0(2), 'ko', 'MarkerFaceColor', 'w', 'DisplayName', 'Start');
    plot(theta_best(1), theta_best(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, ...
        'DisplayName', 'Final');
    plot_attempt_layers(history, true, color_limits);
    xlabel('\theta_1');
    ylabel('\theta_2');
    title('Accepted path and failed searches');
    grid on;
    axis tight;
    hold off;

    sgtitle('Gradient descent debug view');
end

function plot_attempt_layers(history, emphasize_accepts, color_limits)
    n_attempts = size(history.attempt_old_theta, 1);
    if n_attempts == 0
        text(0.5, 0.5, 'No attempts recorded', 'Units', 'normalized', ...
            'HorizontalAlignment', 'center');
        return;
    end

    if nargin < 3 || isempty(color_limits)
        value_min = min(history.attempt_new_value);
        value_max = max(history.attempt_new_value);
        if value_min == value_max
            value_max = value_min + 1;
        end
        color_limits = [value_min, value_max];
        clim(color_limits);
        colormap(parula);
        colorbar;
    end

    iteration_ids = unique(history.attempt_iteration, 'stable');
    cmap = colormap(gca);

    for idx = 1:numel(iteration_ids)
        iteration_id = iteration_ids(idx);
        mask = history.attempt_iteration == iteration_id;

        old_thetas = history.attempt_old_theta(mask, :);
        new_thetas = history.attempt_new_theta(mask, :);
        accepted = history.attempt_accepted(mask);
        values = history.attempt_new_value(mask);

        iteration_color = map_values_to_colors(values(1), cmap, color_limits);

        origin = old_thetas(1, :);
        text(origin(1), origin(2), sprintf(' %d', iteration_id), ...
            'Color', iteration_color, 'FontSize', 8, 'FontWeight', 'bold', ...
            'BackgroundColor', 'w', 'Margin', 0.5, ...
            'VerticalAlignment', 'bottom', 'Clipping', 'on');

        for row = 1:size(new_thetas, 1)
            delta = new_thetas(row, :) - old_thetas(row, :);
            is_accepted = accepted(row);
            point_color = map_values_to_colors(values(row), cmap, color_limits);

            if is_accepted
                line_width = 1.8;
                line_style = '-';
                marker_size = 42;
                arrow_color = point_color;
            elseif emphasize_accepts
                line_width = 0.75;
                line_style = ':';
                marker_size = 28;
                arrow_color = 0.35 * point_color + 0.65 * [1 1 1];
            else
                line_width = 1.0;
                line_style = '--';
                marker_size = 30;
                arrow_color = 0.5 * point_color + 0.5 * [1 1 1];
            end

            quiver(old_thetas(row, 1), old_thetas(row, 2), delta(1), delta(2), 0, ...
                'Color', arrow_color, 'LineStyle', line_style, 'LineWidth', line_width, ...
                'MaxHeadSize', 0.4, 'HandleVisibility', 'off');
            scatter(new_thetas(row, 1), new_thetas(row, 2), marker_size, ...
                'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'k', ...
                'LineWidth', 0.75, ...
                'HandleVisibility', 'off');
        end
    end

    if emphasize_accepts && ~isempty(history.new_theta)
        plot(history.new_theta(:,1), history.new_theta(:,2), 'k-', 'LineWidth', 1.2, ...
            'HandleVisibility', 'off');
    end
end

function colors = map_values_to_colors(values, cmap, color_limits)
    values = values(:);
    n_colors = size(cmap, 1);
    denom = color_limits(2) - color_limits(1);
    if denom <= 0
        denom = 1;
    end
    normalized = (values - color_limits(1)) / denom;
    normalized = min(max(normalized, 0), 1);
    indices = 1 + round(normalized * (n_colors - 1));
    colors = cmap(indices, :);
end
