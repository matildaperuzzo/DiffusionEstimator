function result = run_model_fast_marching(parameters, theta, dataset)
    
    result = struct();

    if nargin > 2
        data = dataset;
    else
        data = parameters.dataset_idx;
    end
    n_data = size(data, 1);
    [~,t0] = min(parameters.dataset_idx(:,3));
    start = parameters.dataset_idx(t0,1:2)';

    [nx, ny, nt] = size(parameters.A);

    A = parameters.A;
    F = theta(1)*ones(nx,ny);

    for i = 1:length(parameters.X)
        F = F + parameters.X{i}*theta(i+1);
    end
    k = 1;
    F = 1./(1 + exp(-k * (F)));
    % F = F./parameters.W;
    
    T = msfm2d(F, start);
    result.T = T;
    result.F = F;
    times = nan(n_data, 1);
    for time = 1:length(data)
        times(time) = T(data(time,1),data(time,2));
    end
    result.times = times';
    result.errors = calculate_error(data, result.times, parameters.dt, "full");
    result.squared_error = sum((data(:,3) - result.times').^2) * parameters.dt.^2 / n_data;
end