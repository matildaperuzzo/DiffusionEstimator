function result = run_model_kpp(parameters, theta, dataset)
    
    result = struct();

    if nargin > 2
        data = dataset;
    else
        data = parameters.dataset_idx;
    end
    n_data = size(data, 1);

    [nx, ny, nt] = size(parameters.A);
    
    A_init = double(parameters.A);
    A_final = zeros(nx, ny, nt);
    A_final(:,:,1) = A_init(:,:,1);

    nt = length(parameters.times);
    sn = 100; % simulation steps per output time step
    ds = 1/sn;

    currentA = parameters.A(:,:,1);
    times = nan(n_data, 1);

    for i = 1:sn*(nt-1)

        nextA = time_step(currentA, theta, parameters, ds);
        nextA = clip(nextA,0,1);
        % update hit times based on the transition from currentA to nextA
        times = update_hit_times(times, data, nextA, i);
        if mod(i, sn) == 0
            A_final(:,:,i/sn+1) = nextA;
        end
        currentA = nextA;
    end


    times(isnan(times)) = nt;
    result.A = A_final;
    result.times = times'/sn;
    result.errors = calculate_error(data, result.times, parameters.dt, "full");
    result.squared_error = sum((data(:,3) - result.times').^2) * parameters.dt.^2 / n_data;

end


function A_t = time_step(A, theta, parameters, dt)
    dx = 1; dy = 1;
    D = linear_diffusivity(A, theta, parameters);
    k = 1;
    D = 1./(1 + exp(-k * (D)));
    D = D./parameters.W;
    
    diffusion = zeros(size(A));
    
    Dx_face = 0.5 * (D(:,1:end-1) + D(:,2:end));   % x-faces
    Dy_face = 0.5 * (D(1:end-1,:) + D(2:end,:));   % y-faces
    
    flux_x = zeros(size(A, 1), size(A, 2) + 1);
    flux_x(:,2:end-1) = Dx_face .* (A(:,2:end) - A(:,1:end-1)) / dx;
    diffusion = diffusion + (flux_x(:,2:end) - flux_x(:,1:end-1)) / dx;
    
    flux_y = zeros(size(A, 1) + 1, size(A, 2));
    flux_y(2:end-1,:) = Dy_face .* (A(2:end,:) - A(1:end-1,:)) / dy;
    diffusion = diffusion + (flux_y(2:end,:) - flux_y(1:end-1,:)) / dy;

    r = 1; 
    K = 1;
    reaction = r * A .* (1 - A / K);
    A_t = A + dt * (diffusion + reaction);
end

function D = linear_diffusivity(A, theta, parameters)
    D = zeros(size(A));

    if isfield(parameters, 'active_layers')
        active_layers = parameters.active_layers;
        theta_index = 1;
        x_index = 1;

        if numel(active_layers) >= 1 && active_layers(1)
            D = D + theta(theta_index);
            theta_index = theta_index + 1;
        end

        if numel(active_layers) >= 2 && active_layers(2)
            theta_index = theta_index + 1;
        end

        for layer_index = 3:numel(active_layers)
            if active_layers(layer_index)
                D = D + parameters.X{x_index} * theta(theta_index);
                theta_index = theta_index + 1;
                x_index = x_index + 1;
            end
        end
    else
        disp("no active layers in parameters")
        
    end
end

function times = update_hit_times(times, data, A, current_time)
    for i = 1:size(data, 1)
        if isnan(times(i)) && A(data(i,1), data(i,2)) >= 0.5
            times(i) = current_time;
        end
    end
end
