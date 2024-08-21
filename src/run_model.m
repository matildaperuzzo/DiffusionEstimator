
function [A_av,error_av] = run_model(n, A_start, nt, theta, X, data)
    A_av = zeros(size(A_start));
    error_av = 0;
    for rep = 1:n
        A = run_model_av(A_start, nt, theta, X);
        error = calculate_error(A, data);
        A_av = A_av + A/n;
        error_av = error + error/n;
    end
end

function A = run_model_av(A_start, nt, theta, X)
    A = A_start;
    for t = 2:nt
        A(:,:,t) = step(A(:,:,t-1), theta, X);
    end

end

function a = step(a, theta, X)
    %normalize c_x and c_y
    [Fn,Fs,Fw,Fe] = frontier(a); % find adjacent cells to currently activated ones
    F = Fn | Fs | Fw | Fe;
    % theta(1) - average diffusion speed (b0)
    % theta(2) - ratio between EW direction and NS direction (r)
    % theta(3) - contribution of terrain (b1)
    cx = theta(2)/(1+theta(2));
    cy = 1/(1+theta(2));
    M = abs(theta(1)) .* (cx * (Fe+Fw)/2 + cy * (Fn+Fs)/2) + theta(3) * F .* X;
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


