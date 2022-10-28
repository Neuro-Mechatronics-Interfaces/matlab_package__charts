classdef SignalBaseChart < matlab.graphics.chartcontainer.ChartContainer
    % c = SignalBaseChart('YData',Y,Name,Value,...)
    % plots one line with markers at local extrema for every column of matrix Y. 
    % You can also specify the additonal name-value arguments.
    
    properties
        XData (:,1) double = NaN
        YData (:,:) double = NaN
        fc (1,2) double = [25, 400] % Cutoff frequencies
        fs (1,1) double = 4000 % Sample rate
    end
    properties(Access = private,Transient,NonCopyable)
        EMG (:,1) matlab.graphics.chart.primitive.Line
    end
    properties(Access = private)
        XScale = [-4 4]
        XGrid = [repmat((-30.625:8.75:30.625)', 1, 4), ...
                 repmat((-30.625:8.75:30.625)', 1, 4)]
        YGrid = [repmat(35 : -8.75 : 8.75, 8, 1), ...
                 repmat(-8.75 : -8.75 : -35, 8, 1)]
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
                    'LineWidth', 2);
            end
            
            % Determine x-coordinates for electrodes
            xdata = linspace(obj.XScale(1), obj.XScale(2), numel(obj.XData));
            tmp = zscore(obj.YData, 0, 1);
            [b,a] = butter(4,(obj.fc)./(obj.fs / 2),'bandpass');
            ydata = filtfilt(b,a,tmp);

            % Update the lines
            for n = 1:nPlotLinesNeeded
                p(n).XData = xdata + obj.XGrid(n);
                p(n).YData = ydata(:,n) + obj.YGrid(n);
            end
            
            % Delete unneeded lines
            delete(p((nPlotLinesNeeded+1):numel(p)))
            obj.EMG = p(1:nPlotLinesNeeded);
            
        end
    end
end