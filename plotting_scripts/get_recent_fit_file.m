function file = get_recent_fit_file(repo_root, crop, layers)
% Return the newest fit for a crop and set of layers, judged by the
% yyyy-mm-dd_HH-MM stamp in the file name. File modification times are not
% used: a fresh clone gives every file the checkout time, which made the
% choice arbitrary.
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

stamps = NaN(numel(files), 1);
for k = 1:numel(files)
    token = regexp(files(k).name, '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}', 'match', 'once');
    if ~isempty(token)
        stamps(k) = datenum(token, 'yyyy-mm-dd_HH-MM');
    end
end
if all(isnan(stamps))
    error('No fit file for crop %s and layers %s carries a yyyy-mm-dd_HH-MM stamp.', ...
        crop, strjoin(layers, ','));
end

[~, idx] = max(stamps);
file = fullfile(files(idx).folder, files(idx).name);
end
