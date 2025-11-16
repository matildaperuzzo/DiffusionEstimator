clear
addpath('src')
load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\all_wheat_av_csi_sea_50av_2025-11-12_08-45.mat")
theta = theta_optim;

%%
[nx,ny,nt] = size(parameters.A);
A = zeros(nx,ny,nt);
[~,t0] = min(parameters.dataset_idx(:,3));
start = parameters.dataset_idx(t0,1:2);
A(start(1),start(2),1) = 1;

function A_t = time_step(A, theta, parameters)

    D = theta(1)*ones(size(A));
    for i = 1:length(parameters.X)
        D = D + parameters.X{i}*theta(i+1);
    end
    k = 1;
    D = 1./(1 + exp(-k * (D)));
    diffusive_term = del2(A).*D;

    A_t = A + diffusive_term + A.*(1-A);
    A_t = clip(A_t,0,5);

end

for t=1:nt
    A_t = time_step(A(:,:,t), theta, parameters);
    A(:,:,t+1) = A_t;
end

figure
axis xy
pcolor(sum(A, 3))

figure 
axis xy
pcolor(sum(result.A,3))