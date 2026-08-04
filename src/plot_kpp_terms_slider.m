% plot_kpp_terms_slider
% Run this after `parameters` and `theta` or `theta_optim` exist in the
% workspace. It replays the KPP update and opens a slider view of A,
% diffusion, and reaction. By default the slider includes every internal
% KPP substep, not only the saved output frames.

clear kpp_slider_steps_per_output
clear kpp_slider_reaction_rate
clear kpp_slider_match_run_model_indexing
clear kpp_slider_store_all_steps
clear kpp_slider_store_terms

if ~exist('parameters', 'var')
    error('plot_kpp_terms_slider:MissingParameters', ...
        'Expected a workspace variable named parameters.');
end

if exist('theta', 'var')
    theta_for_kpp_slider = theta;
elseif exist('theta_optim', 'var')
    theta_for_kpp_slider = theta_optim;
else
    error('plot_kpp_terms_slider:MissingTheta', ...
        'Expected a workspace variable named theta or theta_optim.');
end

if ~exist('kpp_slider_steps_per_output', 'var')
    kpp_slider_steps_per_output = 100;
end

if ~exist('kpp_slider_reaction_rate', 'var')
    kpp_slider_reaction_rate = 1;
end

if ~exist('kpp_slider_match_run_model_indexing', 'var')
    kpp_slider_match_run_model_indexing = true;
end

if ~exist('kpp_slider_store_all_steps', 'var')
    kpp_slider_store_all_steps = false;
end

if ~exist('kpp_slider_store_terms', 'var')
    kpp_slider_store_terms = false;
end

kpp_terms_result = simulate_kpp_terms_for_slider( ...
    parameters, ...
    theta_for_kpp_slider, ...
    kpp_slider_steps_per_output, ...
    kpp_slider_reaction_rate, ...
    kpp_slider_match_run_model_indexing, ...
    kpp_slider_store_all_steps, ...
    kpp_slider_store_terms);

create_kpp_terms_slider(kpp_terms_result, parameters);

function result = simulate_kpp_terms_for_slider(parameters, theta, steps_per_output, reaction_rate, match_run_model_indexing, store_all_steps, store_terms)
    validateattributes(steps_per_output, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, mfilename, 'steps_per_output');

    [nx, ny, nt_from_A] = size(parameters.A);
    if isfield(parameters, 'times')
        nt = numel(parameters.times);
    else
        nt = nt_from_A;
    end

    theta = theta(:)';
    ds = 1 / steps_per_output;
    currentA = double(parameters.A(:, :, 1));

    if store_all_steps
        if match_run_model_indexing
            n_steps = steps_per_output * nt;
            n_frames = n_steps;
            frame_offset = 0;
            model_steps = (1:n_frames)';
        else
            n_steps = steps_per_output * max(nt - 1, 0);
            n_frames = n_steps + 1;
            frame_offset = 1;
            model_steps = (0:n_steps)';
        end
    else
        n_frames = nt;
        frame_offset = 0;
        if match_run_model_indexing
            n_steps = steps_per_output * nt;
            model_steps = (steps_per_output:steps_per_output:n_steps)';
        else
            n_steps = steps_per_output * max(nt - 1, 0);
            frame_offset = 1;
            model_steps = (0:steps_per_output:n_steps)';
        end
    end

    arrays_to_store = 1 + 3 * double(store_terms);
    estimated_gb = double(nx) * double(ny) * double(n_frames) * 4 * arrays_to_store / 1024^3;
    if estimated_gb > 2
        warning('plot_kpp_terms_slider:LargeDebugArray', ...
            'Stored KPP debug arrays use approximately %.2f GB.', estimated_gb);
    end

    A_series = zeros(nx, ny, n_frames, 'single');
    if ~match_run_model_indexing
        A_series(:, :, 1) = single(currentA);
    end

    for step_index = 1:n_steps
        currentA = kpp_advance_one_step(currentA, theta, parameters, ds, reaction_rate);

        if store_all_steps
            A_series(:, :, step_index + frame_offset) = single(currentA);
        elseif mod(step_index, steps_per_output) == 0
            output_index = step_index / steps_per_output + frame_offset;
            A_series(:, :, output_index) = single(currentA);
        end
    end
 
    if store_terms
        diffusion_series = zeros(nx, ny, n_frames, 'single');
        reaction_series = zeros(nx, ny, n_frames, 'single');
        diffusivity_series = zeros(nx, ny, n_frames, 'single');
        for output_index = 1:n_frames
            [diffusion_frame, reaction_frame, diffusivity_frame] = ...
                kpp_terms(double(A_series(:, :, output_index)), theta, parameters, reaction_rate);
            diffusion_series(:, :, output_index) = single(diffusion_frame);
            reaction_series(:, :, output_index) = single(reaction_frame);
            diffusivity_series(:, :, output_index) = single(diffusivity_frame);
        end
    else
        diffusion_series = [];
        reaction_series = [];
        diffusivity_series = [];
    end

    result = struct();
    result.A = A_series;
    result.diffusion = diffusion_series;
    result.reaction = reaction_series;
    result.diffusivity = diffusivity_series;
    result.theta = theta;
    result.model_steps = model_steps(:);
    result.steps_per_output = steps_per_output;
    result.reaction_rate = reaction_rate;
    result.match_run_model_indexing = match_run_model_indexing;
    result.store_all_steps = store_all_steps;
    result.store_terms = store_terms;

    if isfield(parameters, 'times') && ~isempty(parameters.times)
        result.times = parameters.times(1) + result.model_steps * ds;
    else
        result.times = result.model_steps / steps_per_output;
    end
end

function A_next = kpp_advance_one_step(A, theta, parameters, dt, reaction_rate)
    [diffusion, reaction] = kpp_terms(A, theta, parameters, reaction_rate);
    A_next = A + dt * (diffusion + reaction);
    A_next = min(max(A_next, 0), 1);
end

function [diffusion, reaction, D] = kpp_terms(A, theta, parameters, reaction_rate)
    dx = 1;
    dy = 1;

    D = linear_diffusivity_for_kpp_slider(A, theta, parameters);
    k = 1;
    D = 1 ./ (1 + exp(-k * D));
    D = D ./ parameters.W;

    diffusion = zeros(size(A));

    Dx_face = 0.5 * (D(:, 1:end-1) + D(:, 2:end));
    Dy_face = 0.5 * (D(1:end-1, :) + D(2:end, :));

    flux_x = zeros(size(A, 1), size(A, 2) + 1);
    flux_x(:, 2:end-1) = Dx_face .* (A(:, 2:end) - A(:, 1:end-1)) / dx;
    diffusion = diffusion + (flux_x(:, 2:end) - flux_x(:, 1:end-1)) / dx;

    flux_y = zeros(size(A, 1) + 1, size(A, 2));
    flux_y(2:end-1, :) = Dy_face .* (A(2:end, :) - A(1:end-1, :)) / dy;
    diffusion = diffusion + (flux_y(2:end, :) - flux_y(1:end-1, :)) / dy;

    K = 1;
    reaction = reaction_rate * A .* (1 - A / K);
end

function D = linear_diffusivity_for_kpp_slider(A, theta, parameters)
    D = zeros(size(A));

    if isfield(parameters, 'active_layers')
        active_layers = parameters.active_layers;
        theta_index = 1;
        x_index = 1;

        if numel(active_layers) >= 1 && active_layers(1)
            D = D + theta(theta_index);
            theta_index = theta_index + 1;
        end

        if numel(active_layers) >= 2 && active_layers(2)
            theta_index = theta_index + 1;
        end

        for layer_index = 3:numel(active_layers)
            if active_layers(layer_index)
                D = D + parameters.X{x_index} * theta(theta_index);
                theta_index = theta_index + 1;
                x_index = x_index + 1;
            end
        end
    else
        D = D + theta(1);
        for x_index = 1:length(parameters.X)
            D = D + parameters.X{x_index} * theta(x_index + 1);
        end
    end
end

function create_kpp_terms_slider(result, parameters)
    n_frames = size(result.A, 3);

    fig = figure( ...
        'Name', 'KPP terms slider', ...
        'Color', 'w', ...
        'Units', 'normalized', ...
        'Position', [0.05 0.1 0.9 0.75]);

    ax = gobjects(1, 3);
    ax(1) = axes('Parent', fig, 'Position', [0.05 0.2 0.27 0.68]);
    ax(2) = axes('Parent', fig, 'Position', [0.37 0.2 0.27 0.68]);
    ax(3) = axes('Parent', fig, 'Position', [0.69 0.2 0.27 0.68]);

    [x_axis, y_axis, has_geo_axes] = slider_plot_axes(parameters, size(result.A, 1), size(result.A, 2));
    [diffusion_frame, reaction_frame] = get_kpp_slider_terms(result, parameters, 1);

    image_handles = gobjects(1, 3);
    image_handles(1) = draw_kpp_image(ax(1), result.A(:, :, 1), x_axis, y_axis, has_geo_axes);
    image_handles(2) = draw_kpp_image(ax(2), diffusion_frame, x_axis, y_axis, has_geo_axes);
    image_handles(3) = draw_kpp_image(ax(3), reaction_frame, x_axis, y_axis, has_geo_axes);

    title(ax(1), 'A');
    title(ax(2), 'Diffusion');
    title(ax(3), 'Reaction');

    colormap(ax(1), parula);
    colormap(ax(2), redblue_colormap_for_kpp_slider());
    colormap(ax(3), hot);

    clim(ax(1), [0 1]);
    if result.store_terms
        clim(ax(2), finite_clim(result.diffusion, true));
        clim(ax(3), finite_clim(result.reaction, false));
    else
        clim(ax(2), finite_clim(diffusion_frame, true));
        clim(ax(3), finite_clim(reaction_frame, false));
    end

    for ax_index = 1:3
        colorbar(ax(ax_index));
        axis(ax(ax_index), 'image');
        axis(ax(ax_index), 'xy');
        if has_geo_axes
            xlabel(ax(ax_index), 'Longitude');
            ylabel(ax(ax_index), 'Latitude');
        else
            xlabel(ax(ax_index), 'Column');
            ylabel(ax(ax_index), 'Row');
        end
    end

    frame_text = uicontrol( ...
        'Parent', fig, ...
        'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.05 0.09 0.28 0.04], ...
        'BackgroundColor', 'w', ...
        'HorizontalAlignment', 'left');

    if n_frames > 1
        slider_step = [1 / (n_frames - 1), min(10 / (n_frames - 1), 1)];
        slider_max = n_frames;
        slider_enable = 'on';
    else
        slider_step = [1 1];
        slider_max = 2;
        slider_enable = 'off';
    end

    slider = uicontrol( ...
        'Parent', fig, ...
        'Style', 'slider', ...
        'Units', 'normalized', ...
        'Position', [0.34 0.095 0.44 0.035], ...
        'Min', 1, ...
        'Max', slider_max, ...
        'Value', 1, ...
        'SliderStep', slider_step, ...
        'Enable', slider_enable, ...
        'Callback', @slider_callback);

    uicontrol( ...
        'Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', '<', ...
        'Units', 'normalized', ...
        'Position', [0.80 0.09 0.04 0.045], ...
        'Callback', @(~, ~) set_frame(get_current_frame() - 1));

    uicontrol( ...
        'Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', '>', ...
        'Units', 'normalized', ...
        'Position', [0.85 0.09 0.04 0.045], ...
        'Callback', @(~, ~) set_frame(get_current_frame() + 1));

    try
        continuous_listener = addlistener(slider, 'ContinuousValueChange', @slider_callback);
        set(slider, 'UserData', continuous_listener);
    catch
        % Older MATLAB releases only update the view when the slider is released.
    end

    set_frame(1);

    function slider_callback(~, ~)
        set_frame(round(get(slider, 'Value')));
    end

    function frame_index = get_current_frame()
        frame_index = round(get(slider, 'Value'));
    end

    function set_frame(frame_index)
        frame_index = max(1, min(n_frames, round(frame_index)));
        set(slider, 'Value', frame_index);

        [diffusion_current, reaction_current] = ...
            get_kpp_slider_terms(result, parameters, frame_index);

        set(image_handles(1), 'CData', result.A(:, :, frame_index));
        set(image_handles(2), 'CData', diffusion_current);
        set(image_handles(3), 'CData', reaction_current);

        if ~result.store_terms
            clim(ax(2), finite_clim(diffusion_current, true));
            clim(ax(3), finite_clim(reaction_current, false));
        end

        if isfield(result, 'times') && numel(result.times) >= frame_index
            time_text = sprintf('time %.4g', result.times(frame_index));
        else
            time_text = sprintf('time index %d', frame_index);
        end

        if result.match_run_model_indexing
            indexing_text = 'run_model_kpp indexing';
        else
            indexing_text = 'initial condition at frame 1';
        end

        if result.store_all_steps
            frame_mode_text = 'all internal substeps';
        else
            frame_mode_text = 'output frames only';
        end

        set(frame_text, 'String', sprintf('Frame %d/%d, substep %d, %s', ...
            frame_index, n_frames, result.model_steps(frame_index), time_text));
        sgtitle(fig, sprintf('KPP terms, %s, %s, %d substeps/output, r = %.4g', ...
            frame_mode_text, indexing_text, result.steps_per_output, result.reaction_rate));

        drawnow limitrate;
    end
end

function [diffusion_frame, reaction_frame] = get_kpp_slider_terms(result, parameters, frame_index)
    if result.store_terms
        diffusion_frame = result.diffusion(:, :, frame_index);
        reaction_frame = result.reaction(:, :, frame_index);
    else
        [diffusion_frame, reaction_frame] = kpp_terms( ...
            double(result.A(:, :, frame_index)), ...
            result.theta, ...
            parameters, ...
            result.reaction_rate);
    end
end

function image_handle = draw_kpp_image(ax, values, x_axis, y_axis, has_geo_axes)
    if has_geo_axes
        image_handle = imagesc(ax, x_axis, y_axis, values);
    else
        image_handle = imagesc(ax, values);
    end
end

function [x_axis, y_axis, has_geo_axes] = slider_plot_axes(parameters, nx, ny)
    has_geo_axes = isfield(parameters, 'lat') && isfield(parameters, 'lon') ...
        && numel(parameters.lat) == 2 && numel(parameters.lon) == 2;

    if has_geo_axes
        y_axis = linspace(parameters.lat(1), parameters.lat(2), nx);
        x_axis = linspace(parameters.lon(1), parameters.lon(2), ny);
    else
        y_axis = 1:nx;
        x_axis = 1:ny;
    end
end

function lim = finite_clim(values, symmetric)
    values = values(isfinite(values));
    if isempty(values)
        lim = [-1 1];
        return;
    end

    if symmetric
        max_abs_value = max(abs(values(:)));
        if max_abs_value == 0
            max_abs_value = 1;
        end
        lim = [-max_abs_value max_abs_value];
    else
        min_value = min(values(:));
        max_value = max(values(:));
        if min_value == max_value
            pad = max(abs(max_value), 1) * 0.01;
            min_value = min_value - pad;
            max_value = max_value + pad;
        end
        lim = [min_value max_value];
    end
end

function cmap = redblue_colormap_for_kpp_slider()
    n = 256;
    lower = [linspace(0, 1, n / 2)', linspace(0, 1, n / 2)', ones(n / 2, 1)];
    upper = [ones(n / 2, 1), linspace(1, 0, n / 2)', linspace(1, 0, n / 2)'];
    cmap = [lower; upper];
end
