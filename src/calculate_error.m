function error = calculate_error(A, data)
    error = 0.0;
    [r,~] = size(data);

    for event_index = 1:length(data)
        if r == 1
            t_pinhasi = data(3);
            simulation_timeseries = A(data(1), data(2), :);
        else
            t_pinhasi = data(event_index,3);
            simulation_timeseries = A(data(event_index,1), data(event_index,2), :);
        end
        if all(simulation_timeseries == 0)
            t_simulation = 1000;
        else
            t_simulation = find(simulation_timeseries, 1);
        end
        
        error = error + abs(t_pinhasi - t_simulation);
    end
    error = error/length(data);

end