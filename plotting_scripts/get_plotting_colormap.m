function cmap = get_plotting_colormap()
if exist('slanCM', 'file') == 2
    cmap = slanCM('romao');
else
    cmap = parula(256);
end
end
