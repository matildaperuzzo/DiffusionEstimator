% ed_model_comparison.m
% Extended Data Fig. 1: maize arrival-time error under the stochastic cell model
% versus a Fisher-KPP reaction-diffusion model fitted to the same sites with the
% same geographic layers. Reads the stored fits; fits nothing.
%
% Inputs : generated_data/sweep_grad_descent/maize_*_100av_*.mat  (stochastic cell model)
%          generated_data/maize_av_*_ 100 av_ kpp_*.mat           (Fisher-KPP; newest by filename date)
% Output : saved_plots/ed_model_comparison.pdf (vector)
%
% Run from anywhere: the repository root is located from this file's path.

repo = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo, 'plotting_scripts'));
addpath(fullfile(repo, 'src'));

specs = {{'av'}, {'sea'}, {'csi','sea'}, {'hydro','sea'}, {'prec','sea'}, {'tmean','sea'}};
names = {'No geography', 'Sea', 'Sea + crop suitability', 'Sea + river size', ...
         'Sea + precipitation', 'Sea + mean temperature'};

% ---- collect RMSE and its delta-method SE for both models --------------------
db = build_filename_database_impl(fullfile(repo, 'generated_data', 'sweep_grad_descent'), false);
n = numel(specs);
[r_mc, s_mc, r_kpp, s_kpp] = deal(NaN(n, 1));
for i = 1:n
    L = specs{i};
    mc = [];
    for k = 1:numel(db)
        c = db{k};
        if strcmp(c.dataset, 'maize') && isequal(sort(c.layers), sort(L)), mc = c; break; end
    end
    if isempty(mc), error('no MC fit for %s', strjoin(L, '+')); end
    a = load_fit_result(mc.file);

    if isequal(L, {'av'})
        pat = 'maize_av_ 100 av_ kpp_*.mat';
    else
        pat = sprintf('maize_av_%s_ 100 av_ kpp_*.mat', strjoin(L(~strcmp(L, 'av')), '_'));
    end
    fl = dir(fullfile(repo, 'generated_data', pat));
    if isempty(fl), error('no KPP fit for %s', strjoin(L, '+')); end
    stamp = cellfun(@(s) datenum(regexp(s, '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}', 'match', 'once'), ...
        'yyyy-mm-dd_HH-MM'), {fl.name});
    [~, j] = max(stamp);
    b = load_fit_result(fullfile(fl(j).folder, fl(j).name));
    assert(isequal(a.parameters.dataset_idx, b.parameters.dataset_idx), 'site sets differ');

    [r_mc(i), s_mc(i)] = rmse_se(a.result.errors);
    [r_kpp(i), s_kpp(i)] = rmse_se(b.result.errors);
    fprintf('%-24s ours %6.1f (%4.1f) | KPP %6.1f (%4.1f) | n = %d\n', names{i}, ...
        r_mc(i), s_mc(i), r_kpp(i), s_kpp(i), numel(a.result.errors));
end

% ---- figure: 89 mm single column, 7 pt labels / 6.5 pt ticks -----------------
FS_LAB = 7; FS_TICK = 6.5;
W = 8.9; H = 6.2;                                   % cm, display size
c_mc  = [78 122 176] / 255;                         % stochastic cell model (romaO ramp)
c_kpp = [163 103 44] / 255;                         % Fisher-KPP (romaO ramp)
INK   = [0 0 0];                                    % text, axes, error bars

f = figure('Units', 'centimeters', 'Position', [2 2 W H], 'Color', 'w');
ax = axes(f, 'Units', 'centimeters', 'Position', [3.55 0.95 W - 3.55 - 0.35 H - 0.95 - 0.75]);
hold(ax, 'on');
y = (1:n)';  bh = 0.36;
p1 = barh(ax, y - bh/2, r_mc,  bh, 'FaceColor', c_mc,  'EdgeColor', 'none');
p2 = barh(ax, y + bh/2, r_kpp, bh, 'FaceColor', c_kpp, 'EdgeColor', 'none');
errorbar(ax, r_mc,  y - bh/2, s_mc,  'horizontal', 'LineStyle', 'none', 'Color', INK, 'CapSize', 2.5, 'LineWidth', 0.5);
errorbar(ax, r_kpp, y + bh/2, s_kpp, 'horizontal', 'LineStyle', 'none', 'Color', INK, 'CapSize', 2.5, 'LineWidth', 0.5);
set(ax, 'YDir', 'reverse', 'YTick', y, 'YTickLabel', names, 'YLim', [0.4, n + 0.6], ...
    'XLim', [0 1200], 'XTick', 0:250:1000, 'XTickLabel', {'0', '250', '500', '750', '1,000'}, ...
    'FontName', 'Helvetica', 'FontSize', FS_TICK, 'TickDir', 'out', 'TickLength', [0.012 0.012], ...
    'Box', 'off', 'XGrid', 'off', 'YGrid', 'off', 'XColor', INK, 'YColor', INK, 'LineWidth', 0.5, ...
    'Layer', 'top');
xlabel(ax, 'Average arrival-time error (years)', 'FontSize', FS_LAB, 'FontName', 'Helvetica');
ylabel(ax, 'Geographic layers', 'FontSize', FS_LAB, 'FontName', 'Helvetica');
lg = legend(ax, [p1 p2], {'This paper (stochastic cell model)', 'Fisher-KPP reaction-diffusion'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off', ...
    'FontSize', FS_LAB, 'FontName', 'Helvetica');
lg.ItemTokenSize = [8 6];
drawnow;

% ---- layout check: legend, labels and whiskers stay clear (mm) ----------------
ax.Units = 'centimeters'; lg.Units = 'centimeters';
axp = ax.Position; lgp = lg.Position;
xr = diff(ax.XLim);
ends = max([r_mc + s_mc; r_kpp + s_kpp]);
ti = ax.TightInset;
gaps = 10 * [lgp(2) - (axp(2) + axp(4)), ...        % legend above plot area
             H - (lgp(2) + lgp(4)), ...             % legend inside figure top
             lgp(1), ...                            % legend inside figure left
             axp(3) * (ax.XLim(2) - ends) / xr, ... % longest whisker to axis end
             axp(1) - ti(1)];                       % y labels inside figure left
fprintf('tightest gap: %.2f mm\n', min(gaps));
assert(all(gaps > 0), 'collision: a label overlaps or leaves the figure');

out = fullfile(repo, 'saved_plots', 'ed_model_comparison.pdf');
exportgraphics(f, out, 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('wrote %s\n', out);

function [r, se] = rmse_se(e)
% RMSE across sites and its delta-method SE (as rmse_se_total in paper_results_bar_chart.m).
e = e(:); q = e.^2; Q = mean(q); r = sqrt(Q);
se = sqrt(mean((q - Q).^2) / (4 * Q * numel(e)));
end
