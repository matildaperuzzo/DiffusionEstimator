clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
data_path = fullfile(repo_root, 'generated_data');

cd(repo_root);
addpath(fullfile(repo_root, 'src'));
addpath(fullfile(repo_root, 'plotting_scripts'));

% Edit these to choose which fitted 3-parameter model to sweep around.
crop = 'cobo';
layers = {'av', 'asym', 'sea'};

window_size = 0.2;
n_points = 21;

fit_file = get_recent_fit_file(data_path, crop, layers(2:end));
fit = load_fit_result(fit_file);
theta_center = fit.theta_optim(:)';

if numel(theta_center) ~= 3
    error('sweep_3d_local_window expects a 3-parameter fit, but found %d parameters in %s.', ...
        numel(theta_center), fit_file);
end

theta_0 = linspace(theta_center(1) - window_size, theta_center(1) + window_size, n_points);
theta_1 = linspace(theta_center(2) - window_size, theta_center(2) + window_size, n_points);
theta_2 = linspace(theta_center(3) - window_size, theta_center(3) + window_size, n_points);

[T0, T1, T2] = ndgrid(theta_0, theta_1, theta_2);
thetas = [T0(:), T1(:), T2(:)];
all_errors = zeros(size(T0));

fprintf('Loaded fit: %s\n', fit_file);
fprintf('Center theta: %s\n', mat2str(theta_center, 6));
fprintf('Sweeping %d points per dimension over +/- %.4f\n', n_points, window_size);

parfor idx = 1:size(thetas, 1)
    theta = thetas(idx, :);
    result = run_model(fit.parameters, theta);
    all_errors(idx) = result.squared_error;
end

t = datetime;
t.Format = 'yyyy-MM-dd_HH-mm';
output_file = fullfile(data_path, sprintf('%s_%s_3d_local_sweep_%s.mat', ...
    crop, strjoin(layers, '_'), string(t)));

save(output_file, 'crop', 'layers', 'fit_file', 'theta_center', 'window_size', ...
    'n_points', 'theta_0', 'theta_1', 'theta_2', 'all_errors');

fprintf('Saved 3D sweep to %s\n', output_file);
