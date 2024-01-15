classdef Contour__Base_Chart < matlab.graphics.chartcontainer.ChartContainer & ...
        matlab.graphics.chartcontainer.mixin.Colorbar
    % c = Contour__Base_Chart('XData', X, 'YData', Y, 'Name', Value,...)
    % Shades in a square with a given size for every gridded data point. 
    % You can also specify the additonal name-value arguments.
    
    properties(Access = public)
        Channel (1,64) double = 1:64
        Enable  (1,64) logical = true(1,64)
        CData   double = NaN
    end
    properties(Transient,NonCopyable,SetAccess = protected,GetAccess = public)
        EMG (1,1) matlab.graphics.primitive.Image
    end
    properties(SetAccess = protected, GetAccess = public)
        Scale (1, 2) double = nan(1,2) % Scaling to constrain line object "spatial" bounds (mm)
        Outline (:,2) double = [];
        XGrid (:, 8) double = nan(8,8) % X-coordinate centers (mm)
        YGrid (:, 8) double = nan(8,8) % Y-coordinate centers (mm)
        Montage (1,1) string % Can be: "L88" "S88" "L48" "L84"
    end
    properties(Transient,Access=protected)
        Outline_
    end
    methods
        function obj = Contour__Base_Chart(varargin)
            if numel(varargin) == 0
                fig = uifigure('Color', 'w', 'HandleVisibility', 'on');
                figure(fig);
            else
                if isa(varargin{1}, 'matlab.ui.Figure')
                    fig = varargin{1};
                    set(fig, 'HandleVisibility', 'on', 'Color', 'w');
                    figure(fig);
                    varargin(1) = [];
                elseif isa(varargin{1}, 'matlab.graphics.axis.Axes')
                    g = varargin{1};
                    while ~isa(g, 'matlab.ui.Figure')
                        g = g.Parent;
                    end
                    set(g, 'HandleVisibility', 'on', 'Color', 'w');
                    figure(g);
                    varargin(1) = [];
                end

                if numel(varargin) > 0
                    if isnumeric(varargin{1})
                        varargin = ['CData', varargin];
                    end
                end
            end
            obj@matlab.graphics.chartcontainer.ChartContainer(varargin{:});
        end
    end
    methods(Access = protected)
        function setup(obj)
            ax = getAxes(obj);
            set(ax, 'NextPlot', 'add', ...
                'FontName', 'Tahoma');
            colormap(ax, 'jet');
            xlabel(ax, 'X-Grid (mm)', 'FontName', 'Tahoma', 'Color', 'k');
            ylabel(ax, 'Y-Grid (mm)', 'FontName', 'Tahoma', 'Color', 'k');
            obj.EMG = matlab.graphics.primitive.Image(...
                'Parent', ax, ...
                'CData', nan(size(obj.XGrid)), ...
                'CDataMapping', 'scaled');
            obj.ColorbarVisible = 'on';
            obj.Outline_ = line(ax,obj.Outline(:,1),obj.Outline(:,2),'Color','k','LineWidth',1.25);
            obj.Outline_.Annotation.LegendInformation.IconDisplayStyle = 'off';
        end
        function setMontage(obj, montage)
            obj.Montage = montage;
        end
        function update(obj)
            obj.EMG.CData = reshape(obj.CData, 8, 8);
            ax = getAxes(obj);
            dx = diff(obj.EMG.XData) / 14;
            dy = diff(obj.EMG.YData) / 14;
            set(ax, ...
                'XLim', obj.EMG.XData + [-dx, dx], ...
                'YLim', obj.EMG.YData + [-dy, dy]);
            
        end
    end
end