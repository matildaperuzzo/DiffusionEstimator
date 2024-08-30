clear
clc
% Add the directory containing run_model.m to the MATLAB path
addpath('src');

d = 22.5; % distance between two cells
gamma = 10; % km per decade
diff_speed = gamma / d ; % diffusion speed in cells per year

% load build
load('data/prep/geography.mat');

% load pinhasi
pinhasi = readtable( ...
    'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');

pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows

pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
    {'lat', 'lon', 'bp'});

pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
pinhasi.bp = 2000 - pinhasi.bp; % from BP to year
idx = find(pinhasi.bp == min(pinhasi.bp));

% restrict to Europe/Iran range
topleft = [60, -17.19];
bottomright = [15, 65.07];

latidx = lat <= topleft(1) & lat >= bottomright(1);
lonidx = lon >= topleft(2) & lon <= bottomright(2);

latp = lat(latidx);
lonp = lon(lonidx);

[~, index_x] = min(abs(latp - pinhasi.lat(idx)));
[~, index_y] = min(abs(lonp - pinhasi.lon(idx)));

%% define simulation array

dt = 10; % time step in years
start_time = floor(min(pinhasi.bp)/dt)*dt;
end_time = ceil(max(pinhasi.bp)/dt)*dt + 1000; % add 1000 years to end_time
T = round((end_time - start_time)/dt + 1);

times = start_time:dt:end_time;

% create matrix storing x,y,t coordinates of pinhasi sites
pinhasi_active = zeros(length(pinhasi.lat),3);
for event_index = 1:length(pinhasi.lat)
    lat_event = pinhasi.lat(event_index);
    lon_event = pinhasi.lon(event_index);
    [~, index_x] = min(abs(latp - lat_event));
    [~, index_y] = min(abs(lonp - lon_event));
    [~, index_t] = min(abs(times - pinhasi.bp(event_index)));
    pinhasi_active(event_index,:) = [index_x, index_y, index_t];
end

% initialize A
A = false(length(latp), length(lonp), T);
% find event in pinhasi_active with the earliest time
[~, earliest_event] = min(pinhasi_active(:,3));
A(pinhasi_active(earliest_event,1), pinhasi_active(earliest_event,2), 1) = true;

terrain = csidata(latidx, lonidx);
terrain = terrain./max(max(terrain));

% theta(1) - average diffusion speed N-S
% theta(2) - average diffusion speed E-W
% theta(3) - contribution of terrain (b1)
terrain_theta = 0;
x_theta = 0.01;
y_theta = 0.5;
ns = [1 10 20 40 60 80 100];
durations = zeros(length(ns),1);
for t=1:length(ns)
    % theta0 = [0.25 2 0.1];
    theta = [x_theta y_theta terrain_theta];
    tic

    [A,error] = run_model(ns(t), A, T, theta, terrain, pinhasi_active);
    disp(error)

    durations(t) = toc;
    disp(durations(t)) 
    %output theta as table

    % make figure
    pinhasimtx = zeros(length(latp),length(lonp));
    [~, index_x] = min(abs(latp - pinhasi.lat(idx)));
    [~, index_y] = min(abs(lonp - pinhasi.lon(idx)));
    pinhasimtx(index_x,index_y) = 1; 

    land = shaperead('landareas.shp', 'UseGeoCoords', true);

    R = georefcells([latp(1) latp(end)], [lonp(1) lonp(end)], ...
        size(pinhasimtx));
    % plot_map(A, R, pinhasi, pinhasi_active, land, errors(t,:))

end

