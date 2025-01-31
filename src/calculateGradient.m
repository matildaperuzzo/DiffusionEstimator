function grad = calculateGradient(f, x0, epsilon)
    % calculateGradient computes the gradient vector of a scalar function using finite differences.
    %
    % Inputs:
    %   f       - Function handle that takes a vector as input and returns a scalar.
    %   x0      - Vector at which the gradient is computed.
    %   epsilon - Small perturbation value for finite difference (default: 1e-5).
    %
    % Output:
    %   grad - Gradient vector of f at x0.
    
    if nargin < 3
        epsilon = 5e-3; % Default perturbation value
    end
    
    n = length(x0);      % Number of variables
    m = length(f(x0));
    grad = zeros(n, m);  % Initialize gradient vector
    
    % Compute gradient
    for i = 1:n
        % Create perturbation vector
        e_i = zeros(1,n);
        e_i(i) = epsilon;
        
        % Approximate partial derivative
        grad(i,:) = 10*(f(x0 + e_i) - f(x0 - e_i)) / (2 * epsilon);
    end
end
