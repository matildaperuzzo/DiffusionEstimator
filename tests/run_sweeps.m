clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'src'));

data_file = fullfile(repo_root, 'generated_data', ...
    'maize_av_sea_ 100 av_ fast_ 2026-06-11_10-58.mat');

load(data_file);

%%

crop = "maize";

if exist('crop', 'var')
    crop_name = string(crop);
elseif exist('dataset', 'var')
    crop_name = string(dataset);
else
    error('Expected either crop or dataset in %s.', data_file);
end

if crop_name == "cobo"
    parameters.A(76,39,46) = true;
end


n_points = 51;
output_file = fullfile(repo_root, 'generated_data', sprintf('%s_sweep_2d.mat', crop_name));

ranges = [[-2 2]; [-2 2]]; 
theta_center = mean(ranges, 2)';

[theta_min, on_edge, min_error, errors] = sweep(ranges, n_points, 3, parameters, 'fast marching');
theta_0 = linspace(ranges(1,1), ranges(1,2), n_points);
theta_1 = linspace(ranges(2,1), ranges(2,2), n_points);
all_errors = reshape(errors, [n_points, n_points]);

save(output_file, 'all_errors', 'theta_0', 'theta_1', 'theta_center', 'ranges', ...
    'theta_min', 'min_error', 'on_edge', '-mat');

%%
figure;
plot_clim = [];
imagesc(theta_0, theta_1, all_errors');
set(gca, 'YDir', 'normal');
if ~isempty(plot_clim)
    clim(plot_clim);
end
colorbar;
hold on;
plot(theta_center(1), theta_center(2), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8, ...
    'DisplayName', 'Sweep center');
% plot(theta_min(1), theta_min(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12, ...
%     'DisplayName', 'Sweep minimum');
xlabel('\theta_1');
ylabel('\theta_2');
title(sprintf('Objective sweep over bs\\_theta range: %s', crop_name));
grid on;
axis tight;
legend('Location', 'best');
hold off;

fprintf('Saved 2D sweep to %s\n', output_file);
fprintf('Sweep center: %s\n', mat2str(theta_center, 6));
fprintf('Sweep minimum: %s\n', mat2str(theta_min, 6));
fprintf('Minimum error: %.12g\n', min_error);
