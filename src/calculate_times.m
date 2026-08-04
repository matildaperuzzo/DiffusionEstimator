function [times, exitflag_2] = calculate_times(A,data)

    [r,~] = size(data);
    [~, ~, t] = size(A);
    t_simulations = zeros(r,1);
    exitflag = 0;

    for event_index = 1:r
        simulation_timeseries = A(data(event_index,1), data(event_index,2), :);
        if all(simulation_timeseries == 0)
            t_simulations(event_index) = t;
            exitflag = exitflag + 1;
        else
            t_simulations(event_index) = find(simulation_timeseries, 1);
        end
    end
    times = int32(t_simulations);
    if nargout > 1
        exitflag_2 = exitflag/r;
    end
end
