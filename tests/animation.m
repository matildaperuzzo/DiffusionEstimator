addpath('src');
load('generated_data\all_wheat_av_prec_sea_100av_2025-03-28_14-02.mat')

parameters.n = 100;
result = run_model(parameters, theta_optim);
[nx, ny, nt] = size(result.A);
dataset_times = parameters.dataset_idx(:,3);
% for i = 1:nt
%     a = squeeze(result.A(:,:,i));
%     f = find_frontier(a);
%     a(f) = 2;
%     arrived_datapoints = parameters.dataset_idx(parameters.dataset_idx(:,3) < i, 1:2);
%     a(sub2ind([nx, ny], arrived_datapoints(:,1), arrived_datapoints(:,2))) = 1.5;
%     non_arrived_datapoints = parameters.dataset_idx(parameters.dataset_idx(:,3) >= i, 1:2);
%     a(sub2ind([nx, ny], non_arrived_datapoints(:,1), non_arrived_datapoints(:,2))) = -0.5;
%     result.A(:,:,i) = a;
% end

result.A = result.A(:,:,1:4:end);
lats = linspace(parameters.lat(1), parameters.lat(2), nx);
lons = linspace(parameters.lon(1), parameters.lon(2), ny);
% animate(result.A, lats, lons, 'test.gif')
%%
slice = (result.A(:,:,end-40));
[X,Y] = meshgrid(lats, lons);
landscape = fliplr(theta_optim(1) + theta_optim(2)*parameters.X{1} + theta_optim(3)*parameters.X{2});
landscape_speed = (1-landscape/max(landscape(:)));
s = surf(X, Y, landscape_speed');
shading interp
view([105+180,70])