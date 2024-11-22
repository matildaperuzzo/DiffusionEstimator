function H = calculateHessian(f, x0, epsilon)
    % calculateHessian computes the Hessian matrix of a function using finite differences.
    %
    % Inputs:
    %   f       - Function handle that takes a vector as input and returns a scalar.
    %   x0      - Vector around which the Hessian is computed.
    %   epsilon - Small perturbation value for finite difference (default: 1e-5).
    %
    % Output:
    %   H - Hessian matrix of f at x0.
    
    if nargin < 3
        epsilon = 5e-2; % Default perturbation value
    end
    
    n = length(x0);  % Number of variables
    H = zeros(n, n); % Initialize Hessian matrix
    
    % Compute the Hessian matrix
    for i = 1:n
        for j = 1:n
            % Create perturbation vectors
            e_i = zeros(n, 1); e_i(i) = epsilon;
            e_j = zeros(n, 1); e_j(j) = epsilon;
            
            if i == j
                % Diagonal elements: second partial derivatives with respect to x_i
                H(i, j) = (f(x0 + e_i) - 2 * f(x0) + f(x0 - e_i)) / epsilon^2;
            else
                % Off-diagonal elements: mixed second partial derivatives
                H(i, j) = (f(x0 + e_i + e_j) - f(x0 + e_i - e_j) ...
                           - f(x0 - e_i + e_j) + f(x0 - e_i - e_j)) / (4 * epsilon^2);
            end
        end
    end
end
