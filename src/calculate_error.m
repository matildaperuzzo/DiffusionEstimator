function [error, times] = calculate_error(data, times, type)

    t_simulations = times;
    t_data = data(:,3)';
    if type == "absolute"
        errors = abs(t_data - t_simulations);
    elseif type == "squared"
        errors = (t_data - t_simulations).^2;
    elseif type == "root"
        errors = sqrt((t_data - t_simulations));
    elseif type == "full"
        errors = t_data - t_simulations;
    elseif type == "average"
        errors = t_data - t_simulations;
    end

    if type == "full"
        error = errors;
    elseif type == "average"
        error = (mean(errors));
    else
        error = mean(errors);
    end

    if nargout == 2
        times = int32(t_simulations);
    end
end
