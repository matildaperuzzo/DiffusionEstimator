function [theta_min, on_edge, min_error, errors] = sweep(ranges, num_points, max_iter, parameters)

    on_edge = true;

    thetas = getCombinations(ranges, num_points);
    errors = zeros(size(thetas(:,1)));
    
    iter = 1;

    range_size = ranges(:,2) - ranges(:,1);
    range_mean = ranges(:,1) + range_size/2;

    while on_edge
        % w = waitbar(0,"Performing grid search, iteration " + string(iter));
        parfor i = 1:length(thetas(:,1))

            theta = thetas(i,:);
            result = run_model(parameters, theta);
            % calculate error
            error = result.squared_error;
            % store error
            errors(i) = error;
            
            % waitbar(i/length(thetas(:,1)))
        end
        
        % close(w)
        % find minimum error
        [min_error, min_idx] = min(errors(:));
        theta_min = thetas(min_idx,:);

        % Check if the minimum is on the edge
        on_edge = any(theta_min == ranges(:,1)') || any(theta_min == ranges(:,2)');

        if on_edge
            % Generate new parameters
            range_diff = theta_min - range_mean';
            ranges = ranges + range_diff';
            thetas = getCombinations(ranges, num_points);
        else
            break
        end

        if iter > max_iter-1
            break
        end
        iter = iter + 1;
        
    end

end

function combinations = getCombinations(ranges, num_points)
    % ranges: A matrix of size (N x 2) with each row representing [min, max]
    % num_points: Number of points for each linspace range
    
    % Determine the number of dimensions from the size of ranges
    num_dims = size(ranges, 1);
    
    % Generate linspace vectors for each dimension
    vectors = arrayfun(@(i) linspace(ranges(i,1), ranges(i,2), num_points), ...
                       1:num_dims, 'UniformOutput', false);

    % Initialize a cell array for grid to store each dimension's meshgrid
    grid = cell(1, num_dims);

    % Create a grid of all combinations using ndgrid
    [grid{:}] = ndgrid(vectors{:});
    
    % Reshape the grid matrices into a single matrix with each row as a combination
    combinations = cell2mat(cellfun(@(v) v(:), grid, 'UniformOutput', false));
end
