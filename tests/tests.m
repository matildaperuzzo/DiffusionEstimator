% save("sweep_1_avg_dt_20.mat", "errors", "terrain_theta", "x_theta", "y_theta",'final_As');

load("sweep_results_ratio_no_chatter_20_avs.mat")
all_errors = all_errors .^2;
dt = 20;
[min_error, min_error_idx] = min(all_errors(:));
[av_idx, r_idx, terrain_idx] = ind2sub(size(all_errors), min_error_idx);

theory_theta = [0.3, 0.3, 0.0];
theory_av = theory_theta(1);
theory_r = theory_theta(2)/theory_theta(1);
theory_terrain = theory_theta(3);

% find closes indexes to theory values
[~, theory_av_idx] = min(abs(av_theta - theory_av));
[~, theory_r_idx] = min(abs(r_theta - theory_r));
theory_terrain_idx = 1;

sqrt(all_errors(theory_av_idx, theory_r_idx, theory_terrain_idx))

[X,Y] = meshgrid(av_theta,log10(r_theta));

% Define the three colors (RGB format):
color1 = [23/255, 42/255, 80/255];   % Blue
color2 = [235/255, 232/255, 198/255];   % White
color3 = [80/255, 13/255, 23/255];   % Red

% Number of points in your colormap:
numColors = 256; 

% Create a colormap by interpolating between these colors:
cmap = interp1([1, 256], [color2; color3], linspace(1, 256, numColors));

colormap(parula)

figure(1)
pcolor(X,Y,squeeze(all_errors)')
colorbar;
ylabel("log(ratio)")
xlabel("average diffusion speed")
% plot point with lowest error in red
hold on
plot(av_theta(av_idx), log10(r_theta(r_idx)), 'r*', 'MarkerSize',10)
% add text box with error value next to point with white background
annotation('textbox', [0.42 0.46 0.1 0.1], 'String', sprintf('error^{1/2} = %f', sqrt(min_error)), 'EdgeColor', 'none', 'BackgroundColor', 'white', 'HorizontalAlignment', 'center', 'FontSize', 14);
max_abs_value = 1000;%max(abs(all_grad(:)))/20;
clim([0, max_abs_value]);

figure(2)
% plot magnitude of gradient of error in the first 2 dimensions
[all_grad_x, all_grad_y] = gradient(squeeze(all_errors));
all_grad = sqrt(all_grad_x.^2 + all_grad_y.^2);
pcolor(X,Y,all_grad')
colormap(cmap)
xlabel("average diffusion speed")
ylabel("ratio")
c = colorbar;
c.Label.String = 'magnitude of gradient of error';
max_abs_value = 100;%max(abs(all_grad(:)))/20;
clim([0, max_abs_value]);

colorbar;

%% ERROR GIF
if false
    % Create a cell array to store the frames
    frames = cell(1, 10);

    for i = 1:length(terrain_theta)
        % Plot contour plots of errors standardizing the errors
        figure
        pcolor(y_theta, x_theta, dt*sqrt(squeeze(errors(i,:,:))));
        % clim([dt*min(errors(:)), dt*max(errors(:))]);
        clim([dt*sqrt(min(errors(:))) 10000.0]);
        xlabel('theta_x');    
        ylabel('theta_y');

        annotation('textbox', [0 0.9 1 0.1], 'String', sprintf('terrain = %s', string(terrain_theta(i))), 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
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
    filename = '/Users/mperuzzo/Documents/repos/bottlenecks/tests/contour_plots_5_av_dt_20_downsampled.gif';
    for i = 1:length(terrain_theta)
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

if false
    %%cross sections
    if true
        colormap = copper(length(terrain_theta));
        figure
        hold on;
        for i = 1:2:length(terrain_theta)
            plot(x_theta, dt*squeeze(sqrt(errors(i,:,y_idx))), 'Color', colormap(i,:), 'LineWidth', 1.);
            xlabel('θ_y');
            % ylim([1000 2000])
            ylabel('error');
            title('error vs y for different terrain');
        end
    
        figure
        hold on;
        for i = 1:2:length(terrain_theta)
            plot(y_theta, dt*squeeze(sqrt(errors(i,x_idx,:))), 'Color', colormap(i,:),'LineWidth', 1.);
            xlabel('θ_x');
            ylabel('error ');
            % ylim([1000 2000])
            title('error vs x for different terrain');
        end
    end
    x_idx = 1;
    terrain_idx = 1;
    if false
        idxs = find(errors < 55);
        frames = cell(1, length(x_theta));
        for idx = 1:length(x_theta)
            loc = 10;
            fwidth = 20;
            tic
            title = "terrain = " + string(terrain_theta(terrain_idx)) + " y = " + string(x_theta(idx)) + " x = " + string(y_theta(x_idx)) + " error = " + string(10*errors(terrain_idx, x_idx, y_idx));
            f = figure('Units','inches','Position',[loc loc fwidth fwidth/2.2], ...
            'PaperPosition',[.25 .25 8 6]);
            %add title
            annotation('textbox', [0 0.9 1 0.1], 'String', title, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
            hold on;
    
            worldmap(["Ireland", "Iran"])
            axis xy
    
            % color map with A
            geoshow(squeeze(final_As(terrain_idx,idx,y_idx,:,:)), R, 'DisplayType', 'texturemap')
            %make sea white
            geoshow(fliplr([land.Lat]),fliplr([land.Lon]),'DisplayType', ...
                'Polygon', 'FaceColor', 'white', 'FaceAlpha', 0.5)
    
            framem('FLineWidth', 1, 'FontSize', 7)
            % Capture the current frame
            frames{idx} = getframe(gcf);
            
            % Close the figure to avoid overlapping plots
            close(gcf);
        end
        % Create a GIF file from the frames
        filename = '/Users/mperuzzo/Documents/repos/bottlenecks/tests/sweep_y.gif';
        for i = 1:length(x_theta)
            % Convert the frame to an indexed image
            [frame_data, colormap] = rgb2ind(frames{i}.cdata, 256);
            
            % Write the frame to the GIF file
            if i == 1
                imwrite(frame_data, colormap, filename, 'gif', 'LoopCount', Inf, 'DelayTime', 1.0);
            else
                imwrite(frame_data, colormap, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 1.0);
            end
        end
    end

end