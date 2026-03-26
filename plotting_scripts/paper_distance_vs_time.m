clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

data_path = fullfile(repo_root, 'generated_data', 'sweep_grad_descent');
cmap = slanCM('romao');
custom_colors = [cmap(160,:); [0 0 0]; cmap(20,:)];
size_pt = 7;
wgs84 = wgs84Ellipsoid("m");

f = figure();
f.Position = [100 100 500 380];
tiledlayout(3,1, 'Padding', 'none', 'TileSpacing', 'compact');

nexttile
hold on
base_fit = load_fit_result(get_recent_fit_file(data_path, 'all_wheat', {}));
best_fit = load_fit_result(get_recent_fit_file(data_path, 'all_wheat', {'prec', 'sea'}));
[~, min_time_idx] = min(base_fit.parameters.dataset_bp);
dist = distance(base_fit.parameters.dataset_lat, base_fit.parameters.dataset_lon, ...
    base_fit.parameters.dataset_lat(min_time_idx), base_fit.parameters.dataset_lon(min_time_idx), wgs84);
dist_km = dist / 1000;
[~, max_time_idx] = max(dist_km);
[~, ~, t_max] = size(base_fit.result.A);

s1 = scatter(base_fit.parameters.dataset_bp, dist_km, 'Marker', '+');
s1.SizeData = size_pt;
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerEdgeColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = base_fit.parameters.start_time - base_fit.result.times / t_max * ...
    (base_fit.parameters.start_time - base_fit.parameters.end_time);
A = [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B = [dist_km(min_time_idx) dist_km(max_time_idx)];
s2 = line(A, B, 'LineWidth', 1);
s2.Color = custom_colors(2,:);

simulation_times = best_fit.parameters.start_time - best_fit.result.times / t_max * ...
    (best_fit.parameters.start_time - best_fit.parameters.end_time);
s3 = scatter(simulation_times, dist_km);
s3.MarkerFaceColor = custom_colors(3,:);
s3.MarkerEdgeAlpha = 0;
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

s2 = line(A, B);
s2.LineWidth = 1;
s2.Color = custom_colors(2,:);

pt = scatter(A(1), B(1));
pt.SizeData = 200;
pt.LineWidth = 1.0;
pt.MarkerEdgeColor = 'k';
text(A(1), B(1) + 2000, "origin", 'HorizontalAlignment', 'center', ...
    'Interpreter', 'latex', 'FontSize', 8)

ylabel("Distance (km)", 'Interpreter', 'latex')
title("Wheat", "FontSize", 10, 'Interpreter', 'latex')
ylim([-1000,7000])
xlim([-12000,2000])
set(gca, "TickLabelInterpreter", 'latex')

nexttile
hold on
base_fit = load_fit_result(get_recent_fit_file(data_path, 'cobo', {}));
best_fit = load_fit_result(get_recent_fit_file(data_path, 'cobo', {'prec', 'sea'}));
[~, min_time_idx] = min(base_fit.parameters.dataset_bp);
dist = distance(base_fit.parameters.dataset_lat, base_fit.parameters.dataset_lon, ...
    base_fit.parameters.dataset_lat(min_time_idx), base_fit.parameters.dataset_lon(min_time_idx), wgs84);
dist_km = dist / 1000;
[~, ~, t_max] = size(base_fit.result.A);

s1 = scatter(base_fit.parameters.dataset_bp, dist_km, 'Marker', '+');
s1.SizeData = size_pt;
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerEdgeColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = base_fit.parameters.start_time - base_fit.result.times / t_max * ...
    (base_fit.parameters.start_time - base_fit.parameters.end_time);
[~, max_time_idx] = max(simulation_times);
A = [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B = [dist_km(min_time_idx) dist_km(max_time_idx)];
s2 = line(A, B, 'LineWidth', 1.0);
s2.Color = custom_colors(2,:);

pt = scatter(A(1), B(1));
pt.SizeData = 200;
pt.LineWidth = 1.0;
pt.MarkerEdgeColor = 'k';
text(A(1) + 150, B(1) + 2000, "origin 1", 'HorizontalAlignment', 'center', ...
    'Interpreter', 'latex', 'FontSize', 8)

second_dist = dist_km(dist_km > 3500);
second_times = simulation_times(dist_km > 3500);
[~, min_time_idx] = min(second_times);
[~, max_time_idx] = max(second_dist);
A2 = [second_times(min_time_idx) second_times(max_time_idx)];
B2 = [second_dist(min_time_idx) second_dist(max_time_idx)];
s22 = line(A2, B2);
s22.LineWidth = 1;
s22.Color = custom_colors(2,:);

pt = scatter(A2(1), B2(1));
pt.SizeData = 200;
pt.LineWidth = 1.0;
pt.MarkerEdgeColor = 'k';
text(A2(1) - 200, B2(1) + 2000, "origin 2", 'HorizontalAlignment', 'center', ...
    'Interpreter', 'latex', 'FontSize', 8)

simulation_times = best_fit.parameters.start_time - best_fit.result.times / t_max * ...
    (best_fit.parameters.start_time - best_fit.parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

ylabel("Distance (km)", 'Interpreter', 'latex')
title("Rice", "FontSize", 10, 'Interpreter', 'latex')
ylim([-1000, 7000])
xlim([-12000,2000])
set(gca, "TickLabelInterpreter", 'latex')

nexttile
hold on
base_fit = load_fit_result(get_recent_fit_file(data_path, 'maize', {}));
best_fit = load_fit_result(get_recent_fit_file(data_path, 'maize', {'prec', 'sea'}));
[~, min_time_idx] = min(base_fit.parameters.dataset_bp);
dist = distance(base_fit.parameters.dataset_lat, base_fit.parameters.dataset_lon, ...
    base_fit.parameters.dataset_lat(min_time_idx), base_fit.parameters.dataset_lon(min_time_idx), wgs84);
dist_km = dist / 1000;
[~, max_time_idx] = max(dist_km);
[~, ~, t_max] = size(base_fit.result.A);

s1 = scatter(base_fit.parameters.dataset_bp, dist_km, 'Marker', '+');
s1.SizeData = size_pt;
s1.MarkerEdgeColor = custom_colors(1,:);
s1.MarkerFaceColor = custom_colors(1,:);
s1.MarkerFaceAlpha = 0.8;

simulation_times = base_fit.parameters.start_time - base_fit.result.times / t_max * ...
    (base_fit.parameters.start_time - base_fit.parameters.end_time);
A = [simulation_times(min_time_idx) simulation_times(max_time_idx)];
B = [dist_km(min_time_idx) dist_km(max_time_idx)];

dist = sqrt((best_fit.parameters.dataset_lat - best_fit.parameters.dataset_lat(min_time_idx)).^2 + ...
    (best_fit.parameters.dataset_lon - best_fit.parameters.dataset_lon(min_time_idx)).^2);
dist_km = deg2km(dist);
simulation_times = best_fit.parameters.start_time - best_fit.result.times / t_max * ...
    (best_fit.parameters.start_time - best_fit.parameters.end_time);
s3 = scatter(simulation_times, dist_km, 'filled');
s3.MarkerFaceColor = custom_colors(3,:);
s3.SizeData = size_pt;
s3.MarkerFaceAlpha = 0.8;

s2 = line(A, B, 'LineWidth', 1);
s2.Color = custom_colors(2,:);

pt = scatter(A(1), B(1));
pt.SizeData = 200;
pt.LineWidth = 1.0;
pt.MarkerEdgeColor = 'k';
text(A(1), B(1) + 2000, "origin", 'HorizontalAlignment', 'center', ...
    'Interpreter', 'latex', 'FontSize', 8)

xlabel("Time (yr)", 'Interpreter', 'latex')
ylabel("Distance (km)", 'Interpreter', 'latex')
title("Maize", "FontSize", 10, 'Interpreter', 'latex')
ylim([-1000,7000])
xlim([-12000,2000])
legend(["Original dataset", "Simulation with geography", "Baseline estimate"], ...
    "Location", "southwest", 'Interpreter', 'latex')
set(gca, "TickLabelInterpreter", 'latex')

set(gcf, 'Color', 'White', 'Alphamap', 0)
exportgraphics(gcf,"saved_plots/dist_vs_time.pdf", 'ContentType', 'vector')