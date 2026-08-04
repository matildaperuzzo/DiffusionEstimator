clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

fprintf('Building filename database from generated_data\n');
database = build_filename_database_impl(fullfile(repo_root,'generated_data','sweep_grad_descent'), true);
save(fullfile(repo_root, 'generated_data', 'sweep_grad_descent', 'filename_database.mat'), 'database');
fprintf('Saved database to %s\n', fullfile(repo_root, 'generated_data', 'filename_database.mat'));

labels = cell(numel(database), 1);
best_errors = NaN(numel(database), 1);
for i = 1:numel(database)
    labels{i} = sprintf('%s: %s', database{i}.dataset, strjoin(database{i}.layers, ' + '));
    best_errors(i) = database{i}.best_error;
end

[best_errors, order] = sort(best_errors, 'ascend');
labels = labels(order);

figure;
barh(best_errors);
yticks(1:numel(labels));
yticklabels(labels);
xlabel('Best error');
title('Best error for discovered layer combinations');
grid on;
