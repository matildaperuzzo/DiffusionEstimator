clearvars;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
cd(repo_root);
addpath(fullfile(repo_root, 'src'));

fit_model('wheat', {'av'}, true, "", [], 'iid', 10);
