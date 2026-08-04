clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

obj_file = fullfile(repo_root, 'generated_data', 'all_wheat_obj.mat');
if exist(obj_file, 'file') ~= 2
    error('Expected objective surface file at %s.', obj_file);
end

data = load(obj_file);
[X, Y] = meshgrid(data.theta_0, data.theta_1);

f = figure(1);
f.Position = [100 100 700 400];
mesh(X, Y, log10(data.all_errors' / 1e6));
view([110 40]);
colormap(get_plotting_colormap());
xlabel('\theta_1');
ylabel('\theta_2');
zlabel('log_{10}(objective / 10^6)');
