function animate(A_mat, x, y, filename)
% Create a cell array to store the frames
    [~,~,n_frames] = size(A_mat);
    frames = cell(1, n_frames);
    [X,Y] = meshgrid(x,y);
    for i = 1:n_frames
        % Plot contour plots of errors standardizing the errors
        figure
        hold on;
        imagesc(x,y,squeeze(A_mat(:,:,i))')
        clim([min(A_mat(:)), max(A_mat(:))]);
        %add colorbar and label
        c = colorbar;
        c.Label.String = 'average error (years)';
        
        % Capture the current frame
        frames{i} = getframe(gcf);
        
        % Close the figure to avoid overlapping plots
        close(gcf);
    end

    for i = 1:n_frames
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