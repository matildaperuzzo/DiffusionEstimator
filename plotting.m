directory = 'generated_data/';
addpath("src")

function recentIdx = findMostRecentDateStruct(structArray)
    % Convert all date strings to datetime objects
    dates = datetime({structArray.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    
    % Find the index of the most recent date
    [~, recentIdx] = max(dates);
end
database = {};

load('generated_data\all_wheat_av_100av_2025-03-24_11-09.mat')
av_sq_err = result.squared_error;
metadata = struct();
metadata.dataset = "wheat";
metadata.file = 'generated_data\all_wheat_av_100av_2025-03-24_11-09.mat';
metadata.layers = {'av'};

metadata.theta = theta_optim;

database{length(database)+1} = metadata;


all_layers = {'asym' 'csi' 'hydro' 'prec' 'tmean','sea'};
sq_errs = zeros(length(all_layers));



for idx1 = 1:length(all_layers)
    l1 = all_layers(idx1);  % Get current layer from index
    
    for idx2 = 1:length(all_layers)
        l2 = all_layers(idx2);  % Get current layer from index
        if strcmp(l1{1},l2{1})
            layers = l1(1);
        else
            layers = {l1{1}, l2{1}};
        end

        to_find = "all_wheat_av";
        for n = 1:length(layers)
        to_find = [to_find,"_", (layers{n})];
        end
        to_find = [to_find, "_100av*"];
        to_find = strjoin(to_find,"");
        f = dir(fullfile(directory,to_find));
        if length(f)==0
            sq_errs(idx1,idx2) = sq_errs(idx2,idx1);
            continue
        end
        id = findMostRecentDateStruct(f);
        
        file = strjoin([f(id).folder "\" f(id).name], "");

        metadata = struct();
        metadata.dataset = "wheat";
        metadata.file = file;
        metadata.layers = layers;
        load(file)
        metadata.theta = theta_optim;

        database{length(database)+1} = metadata;

        if ~any(strcmp({whos().name},'result'))
            result = run_model(parameters, theta_optim);
            save(file, "result", '-append');
        end
        sq_errs(idx1,idx2) = result.squared_error;
        clear("result")
    end
end
sq_errors = 1 - sq_errs/av_sq_err;

colormap pink
imagesc(sq_errors)
% Set ticks and labels
xticks(1:length(all_layers));  
yticks(1:length(all_layers));
xticklabels(all_layers);
yticklabels(all_layers);

% Rotate x-labels for better readability
xtickangle(45);  % Rotate 45 degrees

% Add colorbar and title
colorbar;
title("Wheat")

%%
load('generated_data\cobo_av_100av_2025-03-31_15-55.mat')
result = run_model(parameters, theta_optim);
metadata = struct();
metadata.dataset = "rice";
metadata.file = "generated_data\cobo_av_100av_2025-03-31_15-55.mat";
metadata.layers = {'av'};
metadata.theta = theta_optim;

database{length(database)+1} = metadata;
av_sq_err = result.squared_error;
all_layers = {'asym' 'csi' 'hydro' 'prec' 'tmean','sea'};
sq_errs = zeros(length(all_layers));

for idx1 = 1:length(all_layers)
    l1 = all_layers(idx1);  % Get current layer from index
    
    for idx2 = 1:length(all_layers)
        l2 = all_layers(idx2);  % Get current layer from index
        if strcmp(l1{1},l2{1})
            layers = l1(1);
        else
            layers = {l1{1}, l2{1}};
        end

        to_find = "cobo_av";
        for n = 1:length(layers)
        to_find = [to_find,"_", (layers{n})];
        end
        to_find = [to_find, "_100av*"];
        to_find = strjoin(to_find,"");
        f = dir(fullfile(directory,to_find));
        if length(f)==0
            sq_errs(idx1,idx2) = sq_errs(idx2,idx1);
            continue
        end
        id = findMostRecentDateStruct(f);
        
        file = strjoin([f(id).folder "\" f(id).name], "");
        metadata = struct();
        metadata.dataset = "rice";
        metadata.file = file;
        metadata.layers = layers;
        load(file)
        metadata.theta = theta_optim;
        database{length(database)+1} = metadata;

        if ~any(strcmp({whos().name},'result'))
            result = run_model(parameters, theta_optim);
            save(file, "result", '-append');
        end
        sq_errs(idx1,idx2) = result.squared_error;
        clear("result")
    end
end
sq_errors = 1 - sq_errs/av_sq_err;
save("generated_data\filename_database.mat", "database")

sq_errors(2,1) = sq_errors(1,2);
colormap pink
imagesc(sq_errors)
% Set ticks and labels
xticks(1:length(all_layers));  
yticks(1:length(all_layers));
xticklabels(all_layers);
yticklabels(all_layers);

% Rotate x-labels for better readability
xtickangle(45);  % Rotate 45 degrees

% Add colorbar and title
colorbar;
title("Rice")

%%
load('generated_data\maize_av_100av_2025-05-16_09-45.mat')
result = run_model(parameters, theta_optim);
metadata = struct();
metadata.dataset = "maize";
metadata.file = 'generated_data\maize_av_100av_2025-05-16_09-45.mat';
metadata.layers = {'av'};
metadata.theta = theta_optim;

database{length(database)+1} = metadata;
av_sq_err = result.squared_error;
all_layers = {'asym' 'csi' 'hydro' 'prec' 'tmean','sea'};
sq_errs = zeros(length(all_layers));

for idx1 = 1:length(all_layers)
    l1 = all_layers(idx1);  % Get current layer from index
    
    for idx2 = 1:length(all_layers)
        l2 = all_layers(idx2);  % Get current layer from index
        if strcmp(l1{1},l2{1})
            layers = l1(1);
        else
            layers = {l1{1}, l2{1}};
        end

        to_find = "maize_av";
        for n = 1:length(layers)
        to_find = [to_find,"_", (layers{n})];
        end
        to_find = [to_find, "_100av*"];
        to_find = strjoin(to_find,"");
        f = dir(fullfile(directory,to_find));
        if length(f)==0
            sq_errs(idx1,idx2) = sq_errs(idx2,idx1);
            continue
        end
        id = findMostRecentDateStruct(f);
        
        file = strjoin([f(id).folder "\" f(id).name], "");
        metadata = struct();
        metadata.dataset = "maize";
        metadata.file = file;
        metadata.layers = layers;
        load(file)
        metadata.theta = theta_optim;
        database{length(database)+1} = metadata;

        if ~any(strcmp({whos().name},'result'))
            result = run_model(parameters, theta_optim);
            save(file, "result", '-append');
        end
        sq_errs(idx1,idx2) = result.squared_error;
        clear("result")
    end
end
sq_errors = 1 - sq_errs/av_sq_err;
save("generated_data\filename_database.mat", "database")

sq_errors(2,1) = sq_errors(1,2);
colormap pink
imagesc(sq_errors)
% Set ticks and labels
xticks(1:length(all_layers));  
yticks(1:length(all_layers));
xticklabels(all_layers);
yticklabels(all_layers);

% Rotate x-labels for better readability
xtickangle(45);  % Rotate 45 degrees

% Add colorbar and title
colorbar;
title("Maize")