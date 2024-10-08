function [A_av, error, arrival_times] = run_model(n, A_start, nt, theta, X, data, U)
    % Initialize the accumulators
    A_av = zeros(size(A_start));
    simulation_times = zeros(1,length(data));

    parfor rep = 1:n
        % Run the model for each instance
        A = run_model_av(A_start, nt, theta, X, U(:,:,:,rep));
        % calculate arrival times
        times = calculate_times(A, data);
        A_av = A_av + double(A);  % Convert to double to accumulate          
        simulation_times = simulation_times + double(times)';

    end

    % Finalize the average
    simulation_times = simulation_times / n;
    A_av = A_av / n;
    error = calculate_error(data, simulation_times, "squared");
    if nargout > 2
        arrival_times = simulation_times;
    end
end


function A = run_model_av(A_start, nt, theta, X, U)
    A = A_start;
    U = squeeze(U);
    for t = 2:nt
        [A(:,:,t)] = step(A(:,:,t-1), theta, X, U(:,:,t));
    end

end


function a = step(a, theta, X, U)
    % a = sparse(a);
    %normalize c_x and c_y
    [Fn,Fs,Fw,Fe] = frontier(a); % find adjacent cells to currently activated ones
    F = Fn | Fs | Fw | Fe;
    % theta(1) - average diffusion speed N-S
    % theta(2) - average diffusion speed E-W
    % theta(3) - contribution of terrain (b1)
    M = theta(1) * (Fe|Fw) + theta(2) * (Fn|Fs) + theta(3) * F .* X;
    % M = abs(theta(1)) .* (cx * (Fe+Fw)/2 + cy * (Fn+Fs)/2) + theta(3) * F .* X;
    f = find(M); % indices of frontier cells
    U = squeeze(U);

    adopt = U(f)<= M(f);
    a(f(adopt)) = true; % update activated cells to include adopters

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
