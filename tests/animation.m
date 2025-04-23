addpath('src');

theta_0 = -0.6 ;
theta_1 = 1.0;
theta_2 = 1.0;

theta = [theta_0 theta_1 theta_2];
active_layers = [1 0 1 1 0];

% % load pinhasi
% pinhasi = readtable( ...
%     'data/raw/pinhasi/Neolithic_timing_Europe_PLOS.xls');
% 
% pinhasi = pinhasi(pinhasi.Var1 == "SITE",:); %% keep only site rows
% 
% pinhasi = renamevars(pinhasi, {'Latitude', 'Longitude', 'CALC14BP'}, ...
%     {'lat', 'lon', 'bp'});
% 
% pinhasi = pinhasi(:,{'lat', 'lon', 'bp'});
% pinhasi.bp = 1950 - pinhasi.bp; % from BP to year
% 
% parameters = data_prep(1, active_layers, pinhasi.lat, pinhasi.lon, pinhasi.bp);
cobo = readtable( ...
     'data/raw/cobo_etal/cobo_etal_data.xlsx');
parameters = data_prep(1, active_layers, cobo.Latitude, cobo.Longitude, cobo.Est_DateMean_BC_AD_);

result = run_model(parameters, theta);
[nx, ny, nt] = size(result.A);
dataset_times = parameters.dataset_idx(:,3);
for i = 1:nt
    a = squeeze(result.A(:,:,i));
    f = find_frontier(a);
    a(f) = 2;
    arrived_datapoints = parameters.dataset_idx(parameters.dataset_idx(:,3) < i, 1:2);
    a(sub2ind([nx, ny], arrived_datapoints(:,1), arrived_datapoints(:,2))) = 1.5;
    non_arrived_datapoints = parameters.dataset_idx(parameters.dataset_idx(:,3) >= i, 1:2);
    a(sub2ind([nx, ny], non_arrived_datapoints(:,1), non_arrived_datapoints(:,2))) = -0.5;
    result.A(:,:,i) = a;
end

result.A = result.A(:,:,1:4:end);
lats = linspace(parameters.lat(1), parameters.lat(2), nx);
lons = linspace(parameters.lon(1), parameters.lon(2), ny);
animate(result.A, lats, lons, 'test.gif')
