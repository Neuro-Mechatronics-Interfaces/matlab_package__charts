classdef Snippet__Base_Chart < matlab.graphics.chartcontainer.ChartContainer
    % c = Snippet__Base_Chart('XData', X, 'YData', Y, 'Name', Value,...)
    % Plots one time-series snippet for every column of matrix Y. 
    % Locations of each column of Y correspond to TMSi- 1-indexed channel
    % ordering schema, which depends on the electrode array Montage that is
    % used in the EMG recording. Subclasses determine the Montage and plot
    % the snippet signals according to the relative channel locations (mm);
    % the length of the snippet is always scaled to fit within a box
    % defined by the extents of the 'Scale' property.
    % You can also specify the additonal name-value arguments.
    %
    % NOTE: Only update 'YData' with data for channels with the
    % corresponding 'Enable' property element set to true. If a channel is
    % not enabled, then do not update 'YData' for that channel.
    
    properties(Access = public)
        Channel (1,64) double = 1:64
        Enable (1,64) logical = true(1,64)
        XData (:,1) double = NaN
        YData (:,:) double = NaN
		LineWidth (1,1) double = 2
        Fc (1,2) double = [25, 400] % Cutoff frequencies
        Fs (1,1) double = 4000 % Sample rate
    end
    properties(Transient,NonCopyable,SetAccess = protected,GetAccess = public)
        EMG (:,1) matlab.graphics.chart.primitive.Line
    end
    properties(SetAccess = protected, GetAccess = public)
        Scale (1, 2) double = nan(1,2) % Scaling to constrain line object "spatial" bounds (mm)
        XGrid (:, 8) double = nan(8,8) % X-coordinate centers (mm)
        YGrid (:, 8) double = nan(8,8) % Y-coordinate centers (mm)
        Montage (1,1) string % Can be: "L88" "S88" "L48" "L84"
    end 
	methods
        function obj = Snippet__Base_Chart(varargin)
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
		function title(obj, varargin)
			ax = getAxes(obj);
			title(ax, varargin{:});
		end
    end
    methods(Access = protected)
        function setup(obj)
            ax = getAxes(obj);
            c = [winter(32); summer(32)];
            set(ax, 'NextPlot', 'add', ...
                'ColorOrder', c, ...
                'FontName', 'Tahoma');
            set(gcf, 'Color', 'w');
            xlabel(ax, 'X-Grid (mm)', 'FontName', 'Tahoma', 'Color', 'k');
            ylabel(ax, 'Y-Grid (mm)', 'FontName', 'Tahoma', 'Color', 'k');
        end
        function setMontage(obj, montage)
            obj.Montage = montage;
        end
        function update(obj)
            % Get the axes
            ax = getAxes(obj);
            
            % Create extra lines as needed
            p = obj.EMG;
            nPlotLinesNeeded = size(obj.YData, 2);
            nPlotLinesHave = numel(p);
            for n = (nPlotLinesHave+1):nPlotLinesNeeded
                p(n) = matlab.graphics.chart.primitive.Line(...
                    'Parent', ax, ...
                    'SeriesIndex', n, ...
                    'LineWidth', obj.LineWidth);
            end
            
            % Determine x-coordinates for electrodes
            if any(isnan(obj.XData))
                xdata = linspace(obj.Scale(1), obj.Scale(2), size(obj.YData,1));
            else
                xdata = linspace(obj.Scale(1), obj.Scale(2), numel(obj.XData));
            end
            tmp = zscore(obj.YData, 0, 1);
            [b,a] = butter(4,(obj.Fc)./(obj.Fs / 2),'bandpass');
            ydata = filtfilt(b,a,tmp);

            ch = obj.Channel(obj.Enable);
            % Update the lines
            for n = 1:nPlotLinesNeeded
                p(n).XData = xdata + obj.XGrid(ch(n));
                p(n).YData = ydata(:,n) + obj.YGrid(ch(n));
            end
            
            % Delete unneeded lines
            delete(p((nPlotLinesNeeded+1):numel(p)))
            obj.EMG = p(1:nPlotLinesNeeded);
            
        end
    end
end