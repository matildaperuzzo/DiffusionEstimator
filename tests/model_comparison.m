% load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\maize_av_sea_ 100 av_ kpp_ 2026-06-09_10-13.mat")
% result_kpp = run_model_kpp(parameters, theta_optim);
% disp(theta_optim)
load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\sweep_grad_descent\maize_av_sea_100av_2026-03-18_09-20.mat")
T_mc = parameters.end_time - parameters.dt*sum(result.A,3);
disp(theta_optim)
addpath("src\")
start_ind = find(parameters.A(:,:,1));
[start_idx,start_idy] = ind2sub(size(parameters.W),start_ind);
start_x = parameters.dataset_lat(start_idx);
start_y = parameters.dataset_lon(start_idx);

F = theta_optim(1)+parameters.X{1}*theta_optim(2);
F = 1./(1 + exp(-F));

% grid_x = linspace(1, length(parameters.W(:,1)), length(parameters.W(:,1)));
% grid_y = linspace(1, length(parameters.W), length(parameters.W));
% 
% T_theory = sqrt((grid_x' - start_idx).^2 + (grid_y-start_idy).^2);
% T_theory = T_theory.*F;

% result_kpp = run_model_kpp(parameters, theta_optim);
% T_kpp = sum(result_kpp.A,3);
% T_kpp = parameters.end_time - T_kpp*parameters.dt;


source = [start_idx start_idy]';
T_fm = msfm2d(F, source, parameters.W);

figure(1)
imagesc(T_mc)
axis xy 
colorbar;
clim([-4000,3000])


figure(2)
imagesc(parameters.start_time + parameters.dt*T_fm)
axis xy
colorbar;
clim([-4000,3000])

figure(3)
imagesc(parameters.start_time + parameters.dt*T_fm - T_mc)
axis xy
colorbar;

load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\maize_av_sea_ 100 av_ fast_ 2026-08-07_13-34.mat")
disp(theta_optim)
start_ind = find(parameters.A(:,:,1));
[start_idx,start_idy] = ind2sub(size(parameters.W),start_ind);
start_x = parameters.dataset_lat(start_idx);
start_y = parameters.dataset_lon(start_idx);

F = theta_optim(1)+parameters.X{1}*theta_optim(2);
F = 1./(1 + exp(-F));
source = [start_idx start_idy]';
T_fm = msfm2d(F, source, parameters.W);

figure(4)
imagesc(parameters.start_time + parameters.dt*T_fm)
axis xy
colorbar;
clim([-4000,3000])

%% Model comparison av only

load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\sweep_grad_descent\maize_av_100av_2026-03-19_09-41.mat")
parameters.W = ones(size(parameters.W));
result = run_model(parameters, theta_optim);
T_mc = parameters.end_time - parameters.dt*sum(result.A,3);
disp(theta_optim)

addpath("src\")
start_ind = find(parameters.A(:,:,1));
[start_idx,start_idy] = ind2sub(size(parameters.W),start_ind);
start_x = parameters.dataset_lat(start_idx);
start_y = parameters.dataset_lon(start_idx);

F = theta_optim(1)*ones(size(parameters.W));
F = 1./(1 + exp(-F));

source = [start_idx start_idy]';
T_fm = msfm2d(F, source, parameters.W);
T_fm = parameters.start_time + parameters.dt*T_fm;

grid_x = linspace(1, length(parameters.W(:,1)), length(parameters.W(:,1)));
grid_y = linspace(1, length(parameters.W), length(parameters.W));

T_theory = sqrt((grid_x' - start_idx).^2 + (grid_y-start_idy).^2);
v_max = 110.567/2/4;
T_theory = T_theory./F;
T_theory = parameters.start_time + T_theory*parameters.dt;

figure (1)
imagesc(T_mc)
axis xy
colorbar

figure (2)
imagesc(T_theory)
axis xy
colorbar
clim([parameters.start_time, parameters.end_time])

figure (3)
imagesc(T_fm)
axis xy
colorbar
clim([parameters.start_time, parameters.end_time])