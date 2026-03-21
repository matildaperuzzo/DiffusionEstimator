clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

% Swap these two paths to compare a different 2D run.
sweep_file = fullfile(repo_root, 'generated_data', 'cobo_sweep_2d.mat');
fit_file = fullfile(repo_root, 'generated_data', 'sweep_grad_descent', ...
    'cobo_av_sea_100av_2026-03-17_13-23.mat');

fit_radius = 15;
% plot_clim = [7.48e5,7.8e5];
plot_clim = [1.425e6, 1.45e6];
contour_scale = 1.0;

sweep_data = load(sweep_file);
fit_data = load(fit_file);

required_sweep_fields = {'all_errors', 'theta_0', 'theta_1'};
for i = 1:numel(required_sweep_fields)
    if ~isfield(sweep_data, required_sweep_fields{i})
        error('Sweep file is missing field %s.', required_sweep_fields{i});
    end
end

if ~isfield(fit_data, 'parameters')
    error('Fit file is missing parameters.');
end

all_errors = sweep_data.all_errors;
theta_0 = sweep_data.theta_0(:);
theta_1 = sweep_data.theta_1(:);
parameters = fit_data.parameters;
if isfield(fit_data, 'bs_theta')
    bs_theta = fit_data.bs_theta;
else
    bs_theta = [];
end

if isfield(fit_data, 'crop')
    crop_name = string(fit_data.crop);
elseif isfield(fit_data, 'dataset')
    crop_name = string(fit_data.dataset);
else
    crop_name = "unknown";
end

if crop_name == "cobo"
    parameters.A(76,39,46) = true;
end

[min_error, min_idx] = min(all_errors(:));
[row_idx, col_idx] = ind2sub(size(all_errors), min_idx);
theta_hat = [theta_0(row_idx), theta_1(col_idx)];

row_window = max(1, row_idx - fit_radius):min(numel(theta_0), row_idx + fit_radius);
col_window = max(1, col_idx - fit_radius):min(numel(theta_1), col_idx + fit_radius);

if numel(row_window) < 3 || numel(col_window) < 3
    error('Not enough grid points around the sweep minimum to fit a local quadratic.');
end

[T0, T1] = ndgrid(theta_0(row_window), theta_1(col_window));
local_errors = all_errors(row_window, col_window);
x = T0(:) - theta_hat(1);
y = T1(:) - theta_hat(2);
z = local_errors(:);

theta_0_step = median(diff(theta_0));
theta_1_step = median(diff(theta_1));
fit_window_position = [
    theta_0(row_window(1)) - theta_0_step / 2, ...
    theta_1(col_window(1)) - theta_1_step / 2, ...
    (theta_0(row_window(end)) - theta_0(row_window(1))) + theta_0_step, ...
    (theta_1(col_window(end)) - theta_1(col_window(1))) + theta_1_step];

design = [ones(size(x)), x, y, x.^2, x .* y, y.^2];
beta = design \ z;

hessian_measured = [2 * beta(4), beta(5); beta(5), 2 * beta(6)];
if rcond(hessian_measured) < 1e-10
    warning('Measured Hessian is ill-conditioned; using pinv.');
    cov_measured_shape = pinv(hessian_measured);
else
    cov_measured_shape = inv(hessian_measured);
end

variance_info = compute_variance(theta_hat, parameters);
cov_analytical = variance_info.V_homo / size(parameters.dataset_idx, 1);

sigma2 = variance_info.sigma2;
cov_measured = 2 * sigma2 * cov_measured_shape / size(parameters.dataset_idx, 1);

[measured_x, measured_y] = covariance_ellipse(cov_measured, theta_hat, contour_scale);
[analytical_x, analytical_y] = covariance_ellipse(cov_analytical, theta_hat, contour_scale);

fprintf('Sweep minimum theta: %s\n', mat2str(theta_hat, 6));
fprintf('Sweep minimum error: %.12g\n', min_error);
fprintf('Measured Hessian:\n');
disp(hessian_measured);
fprintf('Measured covariance estimate (scaled):\n');
disp(cov_measured);
fprintf('Analytical covariance V_homo / L:\n');
disp(cov_analytical);
fprintf('Measured std. errors: %s\n', mat2str(sqrt(max(diag(cov_measured), 0))', 6));
fprintf('Analytical std. errors: %s\n', mat2str(variance_info.se_homo', 6));

figure;
imagesc(theta_0, theta_1, all_errors');
set(gca, 'YDir', 'normal');
if ~isempty(plot_clim)
    clim(plot_clim);
end
colorbar;
hold on;
plot(theta_hat(1), theta_hat(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, ...
    'DisplayName', 'Sweep minimum');
plot(measured_x, measured_y, 'r-', 'LineWidth', 2, ...
    'DisplayName', 'Measured ellipse');
plot(analytical_x, analytical_y, 'k--', 'LineWidth', 2, ...
    'DisplayName', 'Analytical ellipse');
rectangle('Position', fit_window_position, 'EdgeColor', 'w', 'LineWidth', 2, ...
    'LineStyle', '-');
plot(NaN, NaN, 'w-', 'LineWidth', 2, 'DisplayName', 'Quadratic fit window');
if ~isempty(bs_theta)
    valid_bs = all(isfinite(bs_theta), 2) & isfinite(fit_data.bs_errors(:));
    scatter(bs_theta(valid_bs, 1), bs_theta(valid_bs, 2), 24, ...
        fit_data.bs_errors(valid_bs), 'filled', ...
        'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Bootstrap thetas');
end
xlabel('\theta_1');
ylabel('\theta_2');
title(sprintf('Measured vs analytical variance: %s', crop_name));
legend('Location', 'best');
grid on;
axis tight;
hold off;

function [x, y] = covariance_ellipse(covariance, center, scale)
    covariance = (covariance + covariance') / 2;
    [vectors, values] = eig(covariance);
    axes_lengths = sqrt(max(diag(values), 0)) * scale;
    angles = linspace(0, 2 * pi, 200);
    circle = [cos(angles); sin(angles)];
    ellipse = vectors * diag(axes_lengths) * circle;
    x = center(1) + ellipse(1, :);
    y = center(2) + ellipse(2, :);
end
