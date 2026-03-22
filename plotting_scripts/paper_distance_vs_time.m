clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

crop_specs = {
    'all_wheat', 'Wheat'
    'cobo', 'Rice'
    'maize', 'Maize'
};
wgs84 = wgs84Ellipsoid('m');

f = figure();
f.Position = [100 100 500 380];
tiledlayout(3, 1, 'Padding', 'none', 'TileSpacing', 'compact');

for i = 1:size(crop_specs, 1)
    nexttile;
    hold on;
    base_fit = load_fit_result(get_recent_fit_file(repo_root, crop_specs{i, 1}, {}));
    best_fit = load_fit_result(get_recent_fit_file(repo_root, crop_specs{i, 1}, {'prec', 'sea'}));

    [~, min_idx] = min(base_fit.parameters.dataset_bp);
    dist = distance(base_fit.parameters.dataset_lat, base_fit.parameters.dataset_lon, ...
        base_fit.parameters.dataset_lat(min_idx), base_fit.parameters.dataset_lon(min_idx), wgs84) / 1000;
    scatter(base_fit.parameters.dataset_bp, dist, 8, 'k', '+');

    simulation_times = base_fit.parameters.start_time - base_fit.result.times / size(base_fit.result.A, 3) * ...
        (base_fit.parameters.start_time - base_fit.parameters.end_time);
    plot(simulation_times, dist, 'o', 'MarkerSize', 3);

    simulation_times_best = best_fit.parameters.start_time - best_fit.result.times / size(best_fit.result.A, 3) * ...
        (best_fit.parameters.start_time - best_fit.parameters.end_time);
    scatter(simulation_times_best, dist, 8, 'filled');

    xlabel('Time (yr)');
    ylabel('Distance (km)');
    title(crop_specs{i, 2});
    grid on;
end
