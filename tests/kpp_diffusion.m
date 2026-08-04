clear
addpath('src')
load("C:\Users\mperuzzo\OneDrive - Nexus365\Documents\bottlenecks\generated_data\sweep_grad_descent\all_wheat_av_prec_sea_100av_2026-03-22_05-28.mat")
theta = theta_optim;
%%
[nx,ny,nt] = size(parameters.A);
F = theta(1)*ones(nx,ny);
[~,t0] = min(parameters.dataset_idx(:,3));

for i = 1:length(parameters.X)
    F = F + parameters.X{i}*theta(i+1);
end
k = 1;
F = 1./(1 + exp(-k * (F)));
F = F./parameters.W;
start = [parameters.dataset_idx(t0,1:2)'];

[T,Y]=msfm2d(F, start, true, true);

figure 
axis xy
p = imagesc(nt-sum(result.A,3));

figure
axis xy
p = imagesc(T);
clim([0,1.8*nt])

%%
[nx,ny,nt] = size(parameters.A);
A = zeros(nx,ny,nt);
[~,t0] = min(parameters.dataset_idx(:,3));
start = parameters.dataset_idx(t0,1:2);
A(start(1),start(2),1) = 1;

xsim = linspace(parameters.lat(1),parameters.lat(2),nx);
ysim = linspace(parameters.lon(1),parameters.lon(2),ny);
dx = xsim(2)-xsim(1);
dy = ysim(2)-ysim(1);

function A_t = time_step(A, theta, parameters, dx, dy)

    dt = 1e-2;
    D = theta(1)*ones(size(A));
    for i = 1:length(parameters.X)
        D = D + parameters.X{i}*theta(i+1);
    end
    k = 1;
    D = 1./(1 + exp(-k * (D)));
    D = D./parameters.W;
    % dx, dy: grid spacings
    A_t = zeros(size(A));
    
    % dx, dy: grid spacings
    % u, D: Ny x Nx arrays
    
    diffusion = zeros(size(A));
    
    Dx_face = 0.5 * (D(:,1:end-1) + D(:,2:end));   % x-faces
    Dy_face = 0.5 * (D(1:end-1,:) + D(2:end,:));   % y-faces
    
    % x contribution
    diffusion(:,2:end-1) = diffusion(:,2:end-1) + ...
        ( Dx_face(:,2:end)   .* (A(:,3:end)   - A(:,2:end-1)) ...
        - Dx_face(:,1:end-1) .* (A(:,2:end-1) - A(:,1:end-2)) ) / dx^2;
    
    % y contribution
    diffusion(2:end-1,:) = diffusion(2:end-1,:) + ...
        ( Dy_face(2:end,:)   .* (A(3:end,:)   - A(2:end-1,:)) ...
        - Dy_face(1:end-1,:) .* (A(2:end-1,:) - A(1:end-2,:)) ) / dy^2;
    r = 1; 
    K = 1;
    reaction = r * A .* (1 - A / K);
    A_t = A + dt * (diffusion + reaction);
end


for t=1:nt*18
    A_t = time_step(A(:,:,t), theta, parameters, dx, dy);
    A(:,:,t+1) = A_t;
end

figure 
axis xy
p = pcolor(sum(result.A,3));
set(p, 'EdgeColor', 'none');

figure
axis xy
p = pcolor(sum(A, 3)/18);
set(p, 'EdgeColor', 'none');

