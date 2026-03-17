clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

sweep_file = fullfile(repo_root, 'generated_data', 'cobo_sweep_2d.mat');
data_file = fullfile(repo_root, 'generated_data', 'cobo_av_sea_100av_2026-01-06_09-18.mat');

debug_mode = false;
plot_clim = [1.425e6, 1.45e6];
gradient_steps = fliplr(logspace(-2.8, -1.6, 4));
steps = fliplr([-0.01 0.01 0.02 0.05 0.075]);
n_starts = 5;
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
    error('This test script expects a 2-parameter theta.');
end

variance_info = compute_variance(theta_ref, parameters);
ellipse_axes = reshape(variance_info.se_homo, 1, []);

if ~isempty(theta_0) && ~isempty(theta_1)
    sweep_span = min([max(theta_0) - min(theta_0), max(theta_1) - min(theta_1)]);
else
    sweep_span = 1;
end
ellipse_axes = max(ellipse_axes, 0.02 * sweep_span);
start_axes = outside_scale * ellipse_axes;

angles = linspace(0, 2 * pi, n_starts + 1);
angles(end) = [];
start_offsets = [start_axes(1) * cos(angles(:)), start_axes(2) * sin(angles(:))];
start_points = theta_ref + start_offsets;

theta_best_all = zeros(n_starts, numel(theta_ref));
best_error_all = zeros(n_starts, 1);
histories = cell(n_starts, 1);

use_parallel = has_parallel_toolbox();
if use_parallel
    parfor start_idx = 1:n_starts
        [theta_best_all(start_idx,:), best_error_all(start_idx), histories{start_idx}] = ...
            sweep_gradient_descent(start_points(start_idx,:), parameters, gradient_steps, steps, debug_mode);
    end
else
    for start_idx = 1:n_starts
        [theta_best_all(start_idx,:), best_error_all(start_idx), histories{start_idx}] = ...
            sweep_gradient_descent(start_points(start_idx,:), parameters, gradient_steps, steps, debug_mode);
    end
end

[best_error, best_idx] = min(best_error_all);
theta_best = theta_best_all(best_idx,:);

figure;
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
ellipse_x = theta_best(1) + ellipse_axes(1) * cos(ellipse_angles);
ellipse_y = theta_best(2) + ellipse_axes(2) * sin(ellipse_angles);
plot(ellipse_x, ellipse_y, 'k', 'LineWidth', 1.25, 'DisplayName', 'Variance ellipse');

path_colors = lines(n_starts);
for start_idx = 1:n_starts
    history = histories{start_idx};
    color = path_colors(start_idx,:);

    plot(start_points(start_idx,1), start_points(start_idx,2), 'o', ...
        'MarkerFaceColor', color, 'MarkerEdgeColor', 'k', 'MarkerSize', 8, ...
        'DisplayName', sprintf('Start %d', start_idx));

    if ~isempty(history.new_theta)
        path_points = [start_points(start_idx,:); history.new_theta];
        plot(path_points(:,1), path_points(:,2), '-', 'Color', color, ...
            'LineWidth', 1.5, 'HandleVisibility', 'off');

        for move_idx = 1:size(history.new_theta, 1)
            old_theta = history.old_theta(move_idx,:);
            new_theta = history.new_theta(move_idx,:);
            delta = new_theta - old_theta;
            quiver(old_theta(1), old_theta(2), delta(1), delta(2), 0, ...
                'Color', color, 'LineWidth', 1.0, 'MaxHeadSize', 0.45, ...
                'HandleVisibility', 'off');
            scatter(new_theta(1), new_theta(2), 28, 'MarkerFaceColor', color, ...
                'MarkerEdgeColor', 'k', 'LineWidth', 0.7, 'HandleVisibility', 'off');
        end
    end
end

plot(theta_ref(1), theta_ref(2), 'ks', 'MarkerFaceColor', 'w', 'MarkerSize', 9, ...
    'DisplayName', 'Reference theta');
plot(theta_best(1), theta_best(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 13, ...
    'DisplayName', 'Best minimum');

xlabel('\theta_1');
ylabel('\theta_2');
title('Gradient descent from variance-exterior starts');
grid on;
axis tight;
legend('Location', 'bestoutside');
hold off;

summary_table = table((1:n_starts)', start_points(:,1), start_points(:,2), ...
    theta_best_all(:,1), theta_best_all(:,2), best_error_all, ...
    'VariableNames', {'start_id', 'start_theta_1', 'start_theta_2', ...
    'final_theta_1', 'final_theta_2', 'final_error'});

fprintf('\n=== variance-start gradient descent summary ===\n');
fprintf('Reference theta: %s\n', mat2str(theta_ref, 6));
fprintf('Variance ellipse axes: %s\n', mat2str(ellipse_axes, 6));
fprintf('Start ellipse axes: %s\n', mat2str(start_axes, 6));
fprintf('Used parallel: %d\n', use_parallel);
fprintf('Best final theta: %s\n', mat2str(theta_best, 6));
fprintf('Best final error: %.12g\n\n', best_error);
disp(summary_table);

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

    for grad_idx = 1:numel(gradient_steps)
        grad_step = gradient_steps(grad_idx);

        while true
            iteration_count = iteration_count + 1;
            grad = calculateGradient(objective_function_mean, theta, grad_step, 1);
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
                    break;
                end
            end

            if ~found_improvement
                break;
            end
        end
    end

    if move_count == 0
        history.values = value;
    end
end

function tf = has_parallel_toolbox()
    tf = ~isempty(ver('parallel')) && license('test', 'Distrib_Computing_Toolbox');
end
