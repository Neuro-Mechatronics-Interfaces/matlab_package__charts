classdef Raster_Array_8_8_L_Chart < charts.Raster__Base_Chart
    % c = Raster_Array_8_8_L_Chart('YData',Y,Name,Value,...)
    % Shades in a square with a given size for every gridded data point. 
    % You can also specify the additonal name-value arguments.
    %
    % Example:
    %   figure; 
    %   test = charts.Raster_Array_8_8_L_Chart();
    %   while true;
    %       n = randi([1,100],1,1);
    %       test.append(randi([1,64],n,1), repmat(datetime('now'),n,1));
    %       drawnow;
    %       pause(1);
    %   end

    methods
        function obj = Raster_Array_8_8_L_Chart(varargin)
            obj@charts.Raster__Base_Chart(varargin{:});
        end
    end
    methods (Access = protected)
        function setup(obj)
            setup@charts.Raster__Base_Chart(obj);
            obj.Montage = "L88";
            cfg = charts.get_config('config.yaml');
            set(obj, ...
                'XScale', cfg.(obj.Montage).XScale, ...
                'XGrid', reshape(cfg.(obj.Montage).XGrid, 8, 8), ...
                'YGrid', reshape(cfg.(obj.Montage).YGrid, 8, 8));
            set(obj.EMG, ...
                'XData', [min(obj.XGrid(:)), max(obj.XGrid(:))], ...
                'YData', [min(obj.YGrid(:)), max(obj.YGrid(:))]);
        end
    end
end