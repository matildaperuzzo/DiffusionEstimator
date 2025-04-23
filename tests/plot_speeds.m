addpath('src');

function local_speeds = compute_local_speeds(x, y, t)
    % x, y, t are vectors representing the coordinates and time of each point
    % local_speeds will store the averaged local speeds for each point

    num_points = length(x);  % Number of points
    local_speeds = zeros(num_points, 1);  % Initialize local speeds vector

    % Loop over each point to find its local speed
    for i = 1:num_points
        % Compute distances to all other points
        dist = sqrt((x - x(i)).^2 + (y - y(i)).^2);  % Euclidean distance
        time_diff = abs(t - t(i));  % Absolute time difference

        % Ensure we don't include the point itself (distance should not be 0)
        dist(i) = Inf;
        time_diff(i) = Inf;

        valid_indices = (dist>3) & (time_diff > 0);
        valid_dist = dist(valid_indices);
        valid_time_diff = time_diff(valid_indices);

        % Find the indices of the 3 closest points
        [~, sorted_indices] = sort(valid_dist);
        closest_indices = sorted_indices(1:5);

        % Calculate relative speeds for these 3 closest points
        speeds = valid_dist(closest_indices) ./ valid_time_diff(closest_indices);

        % Take the average speed
        local_speeds(i) = mean(speeds, 'omitnan');
    end
end

active_layers = [1 0 1 0 1 0 0];
% cobo = readtable( ...
%      'data/raw/cobo_etal/cobo_etal_data.xlsx');
% load pinhasi
pinhasi = readtable( ...
    'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
    {'lat', 'lon', 'bp'});

pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
pinhasi.bp = 1950 - pinhasi.bp; % from BP to year

x = pinhasi.lat;
y = pinhasi.lon;
t = pinhasi.bp;
parameters = data_prep(50, active_layers, x, y, t);

theta_0 = -1.3351;
theta_1 = 1.5267;



theta = [theta_0 theta_1 ];


result = run_model(parameters, theta);

[min_time, min_idx] = min(parameters.dataset_idx(:,3));

times = parameters.dataset_idx(:,3) - min_time;
lat = parameters.dataset_idx(:,1) - parameters.dataset_idx(min_idx,1);
lon = parameters.dataset_idx(:,2) - parameters.dataset_idx(min_idx,2);

errors = calculate_error(parameters.dataset_idx, result.times, parameters.dt, "full");
plot_map(parameters, errors, true);


%%
figure(3)
hold on;
histogram(errors)
title('Error histogram')
xlabel('Error')
ylabel('Frequency')
fprintf('Elapsed time: %.2f seconds\n', toc);

distances = sqrt(lat.^2 +lon.^2);
speeds_data = distances./times;
P = polyfit(times,distances,1);
figure
hold on;
[distances, distances_ind] = sort(distances);
times = times(distances_ind);
plot(times, distances,'r.')
% plot(times, P(2) + P(1)*times,'r')
xlabel('times/dt')
ylabel('distances/dx')

speeds_model = distances./result.times';
P = polyfit(result.times,distances,1);
result.times = result.times(distances_ind);
plot(result.times, distances,'b.')
% plot(result.times, P(2) + P(1)*result.times,'b')
xlabel('times/dt')
ylabel('distances/dx')
local_speeds = compute_local_speeds(parameters.dataset_idx(:,1),parameters.dataset_idx(:,2),parameters.dataset_idx(:,3));
