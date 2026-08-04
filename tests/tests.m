% save("sweep_1_avg_dt_20.mat", "errors", "terrain_theta", "x_theta", "y_theta",'final_As');

% load("generated_data/Cobo_objective_functions/pinhasi_av_csi.mat")
load("model_plot_sweep_small.mat")
all_errors = errors;
theta_0 = theta_prec;
theta_1 = theta_tmean;

[min_error, min_error_idx] = min(all_errors(:));
[idx_0, idx_1, idx_2] = ind2sub(size(all_errors), min_error_idx);

%% Error landscape and gradient

if true
   
    [X,Y] = meshgrid(theta_0,theta_1);
    
    % Define the three colors (RGB format):
    color1 = [23/255, 42/255, 80/255];   % Blue
    color2 = [235/255, 232/255, 198/255];   % White
    color3 = [80/255, 13/255, 23/255];   % Red
    
    % Number of points in your colormap:
    numColors = 256; 
    
    % Create a colormap by interpolating between these colors:
    cmap = interp1([1, 256], [color2; color3], linspace(1, 256, numColors));
    cmap = interp1([1, 128, 256], [color1; color2; color3], linspace(1, 256, numColors));
    % colormap(parula)
    % f = flag_1+flag_2;
    v = [0.2,0.2];
    ind = idx_1;
    figure(2)
    hold on;
    all_errors = squeeze(all_errors);
    h = pcolor(X,Y,all_errors');
    % contour(X,Y,squeeze(f)',v,'ShowText','on')
    colorbar;
    ylabel("theta_1")
    xlabel("theta_0")
    % plot point with lowest error in red
    hold on
    plot(theta_0(idx_0), theta_1(idx_1), 'r*', 'MarkerSize',10)
    % add text box with error value next to point with white background
    % annotation('textbox', [0.42 0.49 0.1 0.1], 'String', sprintf('error^{1/2} = %f', sqrt(min_error)*dt), 'EdgeColor', 'none', 'BackgroundColor', 'white', 'HorizontalAlignment', 'center', 'FontSize', 14);
    % max_abs_value = max(abs(all_grad(:)));
    clim([min(all_errors(:)), 1.7e6]);
    
    % figure(2)
    % % plot magnitude of gradient of error in the first 2 dimensions
    % [all_grad_x, all_grad_y] = gradient(squeeze(all_errors(:,1,:)));
    % all_grad = sqrt(all_grad_x.^2 + all_grad_y.^2);
    % % pcolor(X,Y,all_grad')
    % pcolor(X,Y,squeeze(flag_1)
    % colormap(cmap)
    % xlabel("average diffusion speed")
    % ylabel("ratio")
    % c = colorbar;
    % c.Label.String = 'magnitude of gradient of error';
    % max_abs_value = max(flag_1(:)-flag_2(:));
    % % clim([-1,1]);
    % colorbar;
end

%% PERCENTAGE ERROR GIF
if true
    % Create a cell array to store the frames
    frames = cell(1, 10);
    [X,Y] = meshgrid(theta_0,theta_2);
    for i = 1:length(theta_1)
        % Plot contour plots of errors standardizing the errors

       theta_0_av = linspace(min(theta_0), max(theta_0),11);

        figure
        hold on;
        pcolor(X,Y,squeeze(all_percentage_errors(:,i,:))')

        clim([min(all_percentage_errors(:)), max(all_percentage_errors(:))]);

        ylabel("theta_0")
        xlabel("theta_2")

        annotation('textbox', [0 0.9 1 0.1], 'String', sprintf('theta_1 = %s', string(theta_1(i))), 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
        % title(sprintf('terrain = %s', string(terrain_theta(i))));
        %add colorbar and label
        c = colorbar;
        c.Label.String = 'average error (years)';
        
        % Capture the current frame
        frames{i} = getframe(gcf);
        
        % Close the figure to avoid overlapping plots
        close(gcf);
    end

    % Create a GIF file from the frames
    filename = '/Users/mperuzzo/Documents/repos/bottlenecks/tests/all_percentage_errors.gif';
    for i = 1:length(theta_1)
        % Convert the frame to an indexed image
        [frame_data, colormap] = rgb2ind(frames{i}.cdata, 256);
        
        % Write the frame to the GIF file
        if i == 1
            imwrite(frame_data, colormap, filename, 'gif', 'LoopCount', Inf, 'DelayTime', 0.5);
        else
            imwrite(frame_data, colormap, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.5);
        end
    end
end

%% ERROR GIF
if true
    % Create a cell array to store the frames
    frames = cell(1, 10);
    [X,Y] = meshgrid(theta_0,theta_2);
    for i = 1:length(theta_1)
        % Plot contour plots of errors standardizing the errors

       theta_0_av = linspace(min(theta_0), max(theta_0),11);

        figure
        hold on;
        pcolor(X,Y,squeeze(all_errors(:,i,:))')

        clim([min(all_errors(:)), max(all_errors(:))]);

        ylabel("theta_0")
        xlabel("theta_2")

        annotation('textbox', [0 0.9 1 0.1], 'String', sprintf('theta_1 = %s', string(theta_1(i))), 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
        % title(sprintf('terrain = %s', string(terrain_theta(i))));
        %add colorbar and label
        c = colorbar;
        c.Label.String = 'average error (years)';
        
        % Capture the current frame
        frames{i} = getframe(gcf);
        
        % Close the figure to avoid overlapping plots
        close(gcf);
    end

    % Create a GIF file from the frames
    filename = '/Users/mperuzzo/Documents/repos/bottlenecks/tests/all_errors.gif';
    for i = 1:length(theta_1)
        % Convert the frame to an indexed image
        [frame_data, colormap] = rgb2ind(frames{i}.cdata, 256);
        
        % Write the frame to the GIF file
        if i == 1
            imwrite(frame_data, colormap, filename, 'gif', 'LoopCount', Inf, 'DelayTime', 0.5);
        else
            imwrite(frame_data, colormap, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.5);
        end
    end
end
