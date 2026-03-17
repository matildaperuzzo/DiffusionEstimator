clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

data_file = fullfile('generated_data', 'cobo_av_sea_100av_2026-01-06_09-18.mat');
output_file = fullfile('generated_data', 'cobo_sweep_2d.mat');

load(data_file);

if strcmp(dataset, 'cobo')
    parameters.A(76,39,46) = true;
end

if exist('theta_start', 'var')
    theta_center = theta_start(:)';
elseif exist('theta_optim', 'var')
    theta_center = theta_optim(:)';
else
    error('Expected theta_start or theta_optim in %s.', data_file);
end

manual_theta_center = [-0.9, -1.5];
if ~isempty(manual_theta_center)
    theta_center = manual_theta_center;
end

half_width = [0.25, 0.25];
n_points = 51;
plot_clim = [1.425e6, 1.45e6];

ranges = [theta_center(:) - half_width(:), theta_center(:) + half_width(:)];

[theta_min, on_edge, min_error, errors] = sweep(ranges, n_points, 0, parameters);
theta_0 = linspace(ranges(1,1), ranges(1,2), n_points);
theta_1 = linspace(ranges(2,1), ranges(2,2), n_points);
all_errors = reshape(errors, [n_points, n_points]);

save(output_file, 'all_errors', 'theta_0', 'theta_1', 'theta_center', 'ranges', ...
    'theta_min', 'min_error', 'on_edge', '-mat');

figure;
imagesc(theta_0, theta_1, all_errors');
set(gca, 'YDir', 'normal');
if ~isempty(plot_clim)
    clim(plot_clim);
end
colorbar;
hold on;
plot(theta_center(1), theta_center(2), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8, ...
    'DisplayName', 'Sweep center');
plot(theta_min(1), theta_min(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, ...
    'DisplayName', 'Sweep minimum');
xlabel('\theta_1');
ylabel('\theta_2');
title('Objective sweep in relevant area');
grid on;
axis tight;
legend('Location', 'best');
hold off;

fprintf('Saved 2D sweep to %s\n', output_file);
fprintf('Sweep center: %s\n', mat2str(theta_center, 6));
fprintf('Sweep minimum: %s\n', mat2str(theta_min, 6));
fprintf('Minimum error: %.12g\n', min_error);

