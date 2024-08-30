function [A_av, error_av] = run_model(n, A_start, nt, theta, X, data)
    % Initialize the accumulators
    A_av = zeros(size(A_start));
    error_sum = 0;

    parfor rep = 1:n
        % Run the model for each instance
        A = run_model_av(A_start, nt, theta, X);
        error = calculate_error(A, data);
        
        % Accumulate the results
        error_sum = error_sum + error;
        A_av = A_av + double(A);  % Convert to double to accumulate
    end

    % Finalize the average
    error_av = error_sum / n;
    A_av = A_av / n;
end


function A = run_model_av(A_start, nt, theta, X)
    A = A_start;
    for t = 2:nt
        A(:,:,t) = step(A(:,:,t-1), theta, X);
    end

end

function a = step(a, theta, X)
    a = sparse(a);
    %normalize c_x and c_y
    [Fn,Fs,Fw,Fe] = frontier(a); % find adjacent cells to currently activated ones
    F = Fn | Fs | Fw | Fe;
    % theta(1) - average diffusion speed N-S
    % theta(2) - average diffusion speed E-W
    % theta(3) - contribution of terrain (b1)

    M = theta(1) * (Fn+Fs)/2 + theta(2) * (Fe+Fw)/2 + theta(3) * F .* X;
    % M = abs(theta(1)) .* (cx * (Fe+Fw)/2 + cy * (Fn+Fs)/2) + theta(3) * F .* X;
    f = find(M); % indices of frontier cells
    
    adopt = rand(length(f),1) <= M(f); % which frontier cells adopt

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


