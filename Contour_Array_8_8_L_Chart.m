classdef Contour_Array_8_8_L_Chart < charts.Contour__Base_Chart
    % c = Contour_Array_8_8_L_Chart('YData',Y,Name,Value,...)
    % Shades in a square with a given size for every gridded data point. 
    % You can also specify the additonal name-value arguments.

    methods
        function obj = Contour_Array_8_8_L_Chart(varargin)
            obj@charts.Contour__Base_Chart(varargin{:});
        end
    end
    methods (Access = protected)
        function setup(obj)
            obj.Montage = "L88";
            cfg = charts.get_config('config.yaml', obj.Montage);
            obj.Outline = [cfg.XOutline; cfg.YOutline]';
            setup@charts.Contour__Base_Chart(obj);
            set(obj, ...
                'XScale', cfg.XScale, ...
                'XGrid', reshape(cfg.XGrid, 8, 8), ...
                'YGrid', reshape(cfg.YGrid, 8, 8));
            set(obj.EMG, ...
                'XData', [min(obj.XGrid(:)), max(obj.XGrid(:))], ...
                'YData', [min(obj.YGrid(:)), max(obj.YGrid(:))]);
        end
    end
end