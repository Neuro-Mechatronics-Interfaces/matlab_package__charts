classdef Contour_Array_8_8_L_Chart < Contour__Base_Chart
    % c = Contour_Array_8_8_L_Chart('YData',Y,Name,Value,...)
    % Shades in a square with a given size for every gridded data point. 
    % You can also specify the additonal name-value arguments.

    methods
        function obj = Contour_Array_8_8_L_Chart(varargin)
            obj@Contour__Base_Chart(varargin{:});
        end
    end
    methods (Access = protected)
        function setup(obj)
            setup@Contour__Base_Chart(obj);
            obj.Montage = "L88";
            cfg = io.yaml.loadFile('config.yaml', "ConvertToArray", true);
            set(obj, ...
                'Scale', cfg.(obj.Montage).Scale, ...
                'XGrid', reshape(cfg.(obj.Montage).XGrid, 8, 8), ...
                'YGrid', reshape(cfg.(obj.Montage).YGrid, 8, 8));
            set(obj.EMG, ...
                'XData', [min(obj.XGrid(:)), max(obj.XGrid(:))], ...
                'YData', [min(obj.YGrid(:)), max(obj.YGrid(:))]);
        end
    end
end