clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

[x, y, t] = get_dataset("all_wheat");
parameters = data_prep(1, [1 0 1 0 0 0 0 0], x, y, t);
land = shaperead('landareas.shp', 'UseGeoCoords', true);
cmap = get_plotting_colormap();

f = figure(1);
set(gcf, 'Color', 'White');
f.Position = [100 100 300 150];
worldmap(parameters.lat, parameters.lon);
colormap(cmap);
colorbar;
hold on;
geoshow(fliplr([land.Lat]), fliplr([land.Lon]), 'DisplayType', 'Polygon', ...
    'FaceColor', 'white', 'FaceAlpha', 0.5);
scatterm(parameters.dataset_lat, parameters.dataset_lon, 3, ...
    parameters.times(parameters.dataset_idx(:, 3)), 'filled');
framem('FLineWidth', 1, 'FontSize', 4);
