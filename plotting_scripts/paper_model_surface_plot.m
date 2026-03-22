clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

fit = load_fit_result(get_recent_fit_file(repo_root, 'all_wheat', {'prec', 'sea'}));
[nx, ny] = size(fit.parameters.X{1});
x = linspace(fit.parameters.lat(1), fit.parameters.lat(2), nx);
y = linspace(fit.parameters.lon(1), fit.parameters.lon(2), ny);
[X, Y] = meshgrid(x, y);

f = figure(1);
f.Position = [100 100 700 400];
mesh(X, Y, fit.parameters.X{1}');
view([45 60]);
colormap(flipud(get_plotting_colormap()));
xlabel('Latitude');
ylabel('Longitude');
zlabel('Layer value');
grid off;
