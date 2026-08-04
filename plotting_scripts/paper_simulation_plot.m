clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

fit = load_fit_result(get_recent_fit_file(repo_root, 'all_wheat', {}));
[x, y, t] = get_dataset("all_wheat");
parameters = data_prep(20, [1 0 1 0 0 0 0 0], x, y, t);
result = run_model(parameters, fit.theta_optim);
land = shaperead('landareas.shp', 'UseGeoCoords', true);
cmap = get_plotting_colormap();

f = figure(1);
set(gcf, 'Color', 'White');
f.Position = [100 100 300 150];
worldmap(parameters.lat, parameters.lon);
colormap(cmap);
simulation = parameters.end_time - mean(result.A, 3) * (parameters.end_time - parameters.start_time);
R = georefcells(parameters.lat, parameters.lon, size(parameters.X{1}));
geoshow(simulation, R, 'DisplayType', 'texturemap');
hold on;
geoshow(fliplr([land.Lat]), fliplr([land.Lon]), 'DisplayType', 'Polygon', ...
    'FaceColor', 'white', 'FaceAlpha', 0.5);
colorbar;
