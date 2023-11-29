% +CHARTS - Plotting utility chart classes designed to show data captured on TMSi surface EMG array grids.  
%
% Utilities
%   get_config                      - Returns the config struct for this submodule.
%
% Helpers
%   tiled_mean_arrays               - Like tiled_snippet_arrays, but shows per-channel means.
%   tiled_snippet_arrays            - Create tiled snippet array figure(s)
%
% Base Classes
%   Contour__Base_Chart             - c = Contour__Base_Chart('XData', X, 'YData', Y, 'Name', Value,...)
%   Raster__Base_Chart              - c = Raster__Base_Chart('TLim', seconds(n), 'Name', Value,...) - Shades in a square with an intensity color for every gridded data point.
%   Snippet__Base_Chart             - c = Snippet__Base_Chart('XData', X, 'YData', Y, 'Name', Value,...)
%
% Specific Layouts
%   Contour_Array_8_8_L_Chart       - c = Contour_Array_8_8_L_Chart('YData',Y,Name,Value,...)
%   Raster_Array_4_8_L_Chart        - c = Raster_Array_4_8_L_Chart('YData',Y,Name,Value,...)
%   Raster_Array_8_4_L_Chart        - c = Raster_Array_8_4_L_Chart('YData',Y,Name,Value,...)
%   Raster_Array_8_8_L_Chart        - c = Raster_Array_8_8_L_Chart('YData',Y,Name,Value,...)
%   Raster_Array_8_8_S_Chart        - c = Raster_Array_8_8_S_Chart('YData',Y,Name,Value,...)
%   Snippet_Array_8_8_L_Chart       - c = Snippet_Array_8_8_L_Chart('YData',Y,Name,Value,...)
%   Snippet_Array_8_8_S_Chart       - c = Snippet_Array_8_8_S_Chart('YData',Y,Name,Value,...)
%   Snippet_Cloth_4_8_L_Chart       - c = Snippet_Cloth_4_8_L_Chart('YData',Y,Name,Value,...)
%   Snippet_Cloth_8_4_L_Chart       - c = Snippet_Cloth_8_4_L_Chart('YData',Y,Name,Value,...)
%
% Examples
%   example_plotting_tiled_snippets - Example showing how to plot tiled snippet files.
