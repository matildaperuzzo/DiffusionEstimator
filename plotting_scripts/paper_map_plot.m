function paper_map_plot(crop)
script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(script_dir);
addpath(fullfile(repo_root, 'src'));

data_path = fullfile(repo_root, 'generated_data', 'sweep_grad_descent');

[fit_crop, title_text, figure_position, overlay_color, output_name] = get_plot_spec(crop);
fit = load_fit_result(get_recent_fit_file(data_path, fit_crop, {'prec', 'sea'}));
simulation = (fit.parameters.end_time - mean(fit.result.A, 3) * ...
    (fit.parameters.end_time - fit.parameters.start_time)) / 1000;

f = figure();
f.Position = figure_position;

if isempty(overlay_color)
    plot_map_flat(fit.parameters, fit.parameters.dataset_bp / 1000, false, simulation);
else
    plot_map_flat(fit.parameters, fit.parameters.dataset_bp / 1000, false, simulation, overlay_color);
end

colormap(slanCM('romao'));
title(title_text, 'Interpreter', 'latex', 'FontSize', 16, 'Color', 'k');
set(gcf, 'Color', 'White', 'Alphamap', 0);
yticks([]);
ylabel([]);
xticks([]);
xlabel([]);

exportgraphics(gcf, fullfile(repo_root, 'saved_plots', output_name), 'ContentType', 'vector');
end

function [fit_crop, title_text, figure_position, overlay_color, output_name] = get_plot_spec(crop)
switch lower(string(crop))
    case {"wheat", "all_wheat"}
        fit_crop = 'all_wheat';
        title_text = "Wheat - sea and precipitation";
        figure_position = [100 100 800 500];
        overlay_color = [];
        output_name = 'maps_and_errors_wheat.svg';
    case {"rice", "cobo"}
        fit_crop = 'cobo';
        title_text = "Rice - sea and precipitation";
        figure_position = [100 100 700 500];
        overlay_color = [1 0.9 1];
        output_name = 'maps_and_errors_rice.svg';
    case "maize"
        fit_crop = 'maize';
        title_text = "Maize - sea and precipitation";
        figure_position = [100 100 500 500];
        overlay_color = [];
        output_name = 'maps_and_errors_maize.svg';
    otherwise
        error('Unknown crop %s. Use wheat, rice, or maize.', crop);
end
end
