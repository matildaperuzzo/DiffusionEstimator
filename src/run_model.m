function result = run_model(parameters, theta, dataset)
    % create result structure
    result = struct();
    % unpack parameters structure
    A_start = (parameters.A);
    
    if nargin > 2
        data = dataset;
    else
        data = (parameters.dataset_idx);
    end
    active_layers = parameters.active_layers;
    X = parameters.X;
    % Initialize the accumulators
    A_av = (zeros(size(A_start)));
    simulation_times = (zeros(1,length(data)));
    % U = parameters.U;
    exitflag_1 = 0;
    exitflag_2 = 0;
    nt = parameters.T;
    dt = parameters.dt;
    squared_error = 0;
    percentage_data = zeros(nt,1);
    percentage_model = zeros(nt,1);
    percentage_squared_error = 0;

    % check if parameters specifies to calculate W
    if isfield(parameters, 'calculate_W')
        calculate_W = parameters.calculate_W;
        W = zeros(length(theta), length(data));
    else
        calculate_W = false;
        W = 0;
    end

    if isfield(parameters,'random')
        rng(parameters.random)
    else
        rng(12)
    end
    data_times = parameters.dataset_idx(:,3);

    for rep = 1:parameters.n
        U = rand(size(A_start)).*parameters.W;
        % Run the model for each instance
        if calculate_W == false
            [A, exfl1] = run_model_av(A_start, nt, theta, X, U, active_layers);
            % calculate arrival times
            [times, exfl2] = calculate_times(A, data);
            
        elseif calculate_W
            f = @(theta)calculate_times(run_model_av(A_start, nt, theta, X, U, active_layers),data)*dt;
            g = calculateGradient(f, theta, 0.001, 1);
            W = W + g;
            [A, exfl1] = run_model_av(A_start, nt, theta, X, U, active_layers);
            % calculate arrival times
            [times, exfl2] = calculate_times(A, data);
        end
        A_av = A_av + double(A);  % Convert to double to accumulate          
        simulation_times = simulation_times + double(times)';

        exitflag_1 = exitflag_1 + exfl1;
        exitflag_2 = exitflag_2 + exfl2;
        
        [per_model, per_data] = get_percentages(parameters, A);
        percentage_data = percentage_data + per_data;
        percentage_model = percentage_model + per_model;
        percentage_squared_error = percentage_squared_error + sum((per_data-per_model).^2);
        
        
    end


    % Finalize the average
    simulation_times = simulation_times / parameters.n ;
    A_av = A_av / parameters.n;

    % assign values to result structure
    result.A = A_av;
    result.times = simulation_times;
    result.errors = calculate_error(data, simulation_times, dt, "full");
    result.squared_error = sum((data_times - simulation_times').^2) * parameters.dt.^2 / length(data);
    result.percentage_squared_error = percentage_squared_error / parameters.n / length(data);
    result.percentage_data = percentage_data / parameters.n;
    result.percentage_model = percentage_model / parameters.n;
    result.exitflag_1 = exitflag_1 / parameters.n;
    result.exitflag_2 = exitflag_2 / parameters.n;

    if calculate_W
        W = W ./ parameters.n;
        W = W*W';
        result.W = W / length(data);
    end
end


function [A, exitflag] = run_model_av(A_start, nt, theta, X, U, active_layers)
    A = A_start;
    U = squeeze(U);
    flag = 0;
    for t = 2:nt
        [extflg1, A(:,:,t)] = step(A(:,:,t-1)+A_start(:,:,t-1), theta, X, U(:,:,t), active_layers);
        flag = flag + extflg1/nt;
    end
    if nargout > 1
        exitflag = flag;
    end
end


function [exfl1,a] = step(a, theta, X, U, active_layers)
    a = sparse(a);

    [Fn,Fs,Fw,Fe] = frontier(a); % find adjacent cells to currently activated ones
    F = Fn | Fs | Fw | Fe;

    theta_ind = 1;
    X_ind = 1;
    M = 0;
    if active_layers(1)
        M = M + theta(theta_ind)*ones(size(F));
        theta_ind = theta_ind + 1;
    end
    if active_layers(2)
        M = M + theta(theta_ind)*(Fe|Fw-Fn|Fs);
        theta_ind = theta_ind + 1;
    end
    for layer = active_layers(3:end)
        if layer
            M = M + theta(theta_ind)*X{X_ind};
            theta_ind = theta_ind + 1;
            X_ind = X_ind + 1;
        end
    end

    M = F .* M;

    f = find(F); % indices of frontier cells
    U = squeeze(U);
    k = 1;
    probabilities = 1./(1 + exp(-k * (M(f))));
    adopt = U(f)<= probabilities;

    a(f(adopt)) = true; % update activated cells to include adopted
    
    exfl1 = mean(M(f));

    if isnan(exfl1)
        exfl1 = 0.5;
    end

end


function [fN, fS, fW, fE] = frontier(A)
    % FRONTIER finds all adjacent cells in a two-dimensional array A to
    % true cells.

    [m,n] = size(A);

    % North
    fN = [diff(A) > 0; false(1,n)];

    % South
    fS = [false(1,n); flipud(diff(flipud(A)) > 0)];

    % West
    fW = [(diff(A') > 0)', false(m,1)];

    % East
    fE = [false(m,1), (flipud(diff(flipud(A')) > 0))'];

    end
