clear
load('C:\Users\matil\OneDrive\Documents\Work\AlanTuring_Oxford\bottlenecks\generated_data\filename_database.mat')
addpath("src")
n_av = 50;
for nd = 1:length(database)
    disp(database{nd}.file)
    load(database{nd}.file)
    if any(strcmp({whos().name},'spread_errors_shuffle'))
        if length(spread_errors_shuffle)==n_av
            spread_errors_shuffle = spread_errors_shuffle(1:n_av);
            save(database{nd}.file, "spread_errors_shuffle", '-append');
            disp("data already available")
            continue
        end
    end

    spread_errors_shuffle = zeros(n_av);
    parameters.random = 'shuffle';
    parfor nav=1:n_av
        result = run_model(parameters, theta_optim);
        spread_errors_shuffle(nav) = result.squared_error;
    end
    parameters.random = 12;
    save(database{nd}.file, "spread_errors_shuffle", '-append');

    clear parameters; clear result;
end