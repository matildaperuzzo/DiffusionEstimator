function file = get_recent_fit_file(repo_root, crop, layers)
directory = repo_root;

if nargin < 3
    layers = {};
end

if ischar(layers) || isstring(layers)
    layers = cellstr(layers);
end

pattern = sprintf('%s_av', crop);
for i = 1:numel(layers)
    pattern = sprintf('%s_%s', pattern, layers{i});
end
pattern = sprintf('%s_100av*.mat', pattern);

files = dir(fullfile(directory, pattern));
if isempty(files)
    error('No generated_data file found for crop %s and layers %s.', crop, strjoin(layers, ','));
end

[~, idx] = max([files.datenum]);
file = fullfile(files(idx).folder, files(idx).name);
end
