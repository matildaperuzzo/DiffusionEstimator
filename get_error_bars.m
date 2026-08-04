clear
load('generated_data\filename_database.mat')
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

    clear parameters; clear result; clear spread_errors_shuffle;
end
%%

av_files = {'generated_data\all_wheat_av_100av_2025-06-14_02-27.mat', 'generated_data\cobo_av_100av_2025-07-10_15-10.mat', 'generated_data\maize_av_100av_2025-06-16_09-06.mat'};
for file = av_files
    clear result; clear parameters; clear spread_errors_shuffle;
    file = file{1};
    disp(file)
    load(file)
    if any(strcmp({whos().name},'spread_errors_shuffle'))
        if length(spread_errors_shuffle)==n_av
            spread_errors_shuffle = spread_errors_shuffle(1:n_av);
            save(file, "spread_errors_shuffle", '-append');
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
    save(file, "spread_errors_shuffle", '-append');

    clear parameters; clear result; clear spread_errors_shuffle;
end