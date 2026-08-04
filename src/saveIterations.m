function stop = saveIterations(x, optimValues, state)
    % Persistent variable to store the fitted parameters
    persistent paramsHistory

    % Initialize if the state is 'init'
    if strcmp(state, 'init')
        paramsHistory = []; % clear history at the beginning
    end

    % Append current parameters to the history during iterations
    if strcmp(state, 'iter')
        paramsHistory = [paramsHistory; x]; 
        assignin('base', 'paramsHistory', paramsHistory); % Save to workspace
    end
    stop = false;
    % No stopping criterion
    if length(paramsHistory)>7
        latest_thetas = paramsHistory(end-4:end,:);
        ref = latest_thetas(1,:);
        if all(latest_thetas == ref,'all')
            stop = true;
        end
    end

end