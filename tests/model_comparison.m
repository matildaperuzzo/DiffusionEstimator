load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\maize_av_ 100 av_ kpp_ 2026-06-10_10-37.mat")
result_kpp = run_model_kpp(parameters, theta_optim);
disp(theta_optim)
load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\sweep_grad_descent\maize_av_100av_2026-03-17_14-40.mat")
%% 
addpath("src\")
[min_time,start_idx] = min(parameters.dataset_bp);
start_idx = parameters.dataset_idx(start_idx,1);
start_idy = parameters.dataset_idx(start_idx,2);
start_x = parameters.dataset_lat(start_idx);
start_y = parameters.dataset_lon(start_idx);

F = theta_optim(1);
F = 1./(1+exp(-F));

grid_x = linspace(1, length(parameters.W(:,1)), length(parameters.W(:,1)));
grid_y = linspace(1, length(parameters.W), length(parameters.W));

T_theory = sqrt((grid_x' - start_idx).^2 + (grid_y-start_idy).^2);
T_theory = T_theory*F;

result_kpp = run_model_kpp(parameters, theta_optim);
T_kpp = sum(result_kpp.A,3);
T_kpp = parameters.end_time - T_kpp*parameters.dt;

source = [start_idx start_idy]';
T_fm = msfm2d(F*ones(size(parameters.W)), source);

figure(1)
axis xy 
imagesc(parameters.start_time + parameters.dt*T_theory)
colorbar;

figure(2)
axis xy
imagesc(parameters.start_time + parameters.dt*T_fm)
colorbar;

figure(3)
axis xy
imagesc(T_kpp)
colorbar;