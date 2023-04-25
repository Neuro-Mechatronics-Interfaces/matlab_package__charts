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
        Axes
        Channel (1,64) double = 1:64
        Color_By_RMS (1,1) logical = true
        Enable (1,64) logical = true(1,64)
        XData (:,1) double = NaN    % Can be used to store time data
        YData (:,:) double = NaN
        TrigData (:,1) double = NaN
        TriggerBit (1,1) double = 9
		LineWidth (1,1) double = 1.25
        Fc double = [] % Cutoff frequencies
        Fs (1,1) double = 4000 % Sample rate
        RMS_Range (1,2) double = [0, 20];    % Expected RMS range for use with Color_By_RMS method of coloration
        RMS_Epoch (1,2) double = [0, 0.030]; % Range used to compute RMS if Color_By_RMS is set to true (default; units should match units of XData)
        Show_Labels (1,1) logical = true;
        XColor = 'k';
        YColor = 'k';
    end
    properties(Transient,NonCopyable,SetAccess = protected,GetAccess = public)
        EMG (:,1) matlab.graphics.chart.primitive.Line
    end
    properties(SetAccess = protected, GetAccess = public)
        YScale (1, 1) double = nan % If non-nan then this used to scale vertical bounds
        XScale (1, 2) double = nan(1,2)% Scaling to constrain line object "spatial" bounds (mm)
        XGrid (:, 8) double = nan(8,8) % X-coordinate centers (mm)
        YGrid (:, 8) double = nan(8,8) % Y-coordinate centers (mm)
        Montage (1,1) string % Can be: "L88" "S88" "L48" "L84"
    end 
    properties(Access = protected)
        CData_
    end
	methods
        function obj = Snippet__Base_Chart(varargin)
            if numel(varargin) == 0
                g = uifigure('Color', 'w', 'HandleVisibility', 'on');
                figure(g);
            else
                if isa(varargin{1}, 'matlab.ui.Figure')
                    g = varargin{1};
                    set(g, 'HandleVisibility', 'on', 'Color', 'w');
                    figure(g);
                    varargin(1) = [];
                elseif isa(varargin{1}, 'matlab.graphics.axis.Axes')
                    g = varargin{1};
                    while ~isa(g, 'matlab.ui.Figure')
                        g = g.Parent;
                    end
                    set(g, 'HandleVisibility', 'on', 'Color', 'w');
                    figure(g);
                    varargin(1) = [];
                elseif isa(varargin{1}, 'matlab.graphics.layout.TiledChartLayout')
                    
                    g = varargin{1};
                    while ~isa(g, 'matlab.ui.Figure')
                        g = g.Parent;
                    end
                    set(g, 'HandleVisibility', 'on', 'Color', 'w');
                    g = varargin{1};
                    varargin(1) = [];
                else
                    g = uifigure('Color', 'w', 'HandleVisibility', 'on');
                    figure(g);
                end

                if numel(varargin) > 0
                    if isnumeric(varargin{1})
                        varargin = ['CData', varargin];
                    end
                end
            end
            obj@matlab.graphics.chartcontainer.ChartContainer(varargin{:});
            for iV = 1:2:numel(varargin)
                obj.(varargin{iV}) = varargin{iV+1};
            end
            obj.Parent = g;
        end
        function ax = getParent(obj)
            ax = getAxes(obj);
        end
		function title(obj, varargin)
			ax = getAxes(obj);
			title(ax, varargin{:});
        end
        function xlabel(obj, varargin)
            ax = getAxes(obj);
            xlabel(ax, varargin{:});
        end
        function ylabel(obj, varargin)
            ax = getAxes(obj);
            ylabel(ax, varargin{:});
        end
        function setRMS_Range(obj, rms_range, c_rms)
            if nargin < 3
                c_rms = cm.map('rosette');
            end
            obj.RMS_Range = rms_range;
            obj.CData_ = cm.cmap(rms_range, c_rms);
            obj.update();
        end
        function refreshAxes(obj)
            ax = getAxes(obj);
            set(ax, ...
                'XColor',obj.XColor,...
                'YColor',obj.YColor,...
                'Colormap', double(obj.CData_(linspace(obj.RMS_Range(1), obj.RMS_Range(2), 64)))./255.0);
            if ~obj.Show_Labels
                xlabel(ax, '', 'FontName', 'Tahoma', 'Color', obj.XColor);
                ylabel(ax, '', 'FontName', 'Tahoma', 'Color', obj.YColor);
            end
        end
    end
    methods(Access = protected)
        function setup(obj)
            ax = getAxes(obj);
            c = [winter(32); summer(32)];
            c_rms = cm.map('rosette');
            c_rms(1,:) = [64 64 64]; % Make the first entry grey;
            obj.CData_ = cm.cmap(obj.RMS_Range, c_rms);
            set(ax, ...
                'NextPlot', 'add', ...
                'XColor',obj.XColor,...
                'YColor',obj.YColor,...
                'ColorOrder', c, ...
                'Colormap', double(obj.CData_(linspace(obj.RMS_Range(1), obj.RMS_Range(2), 64)))./255.0, ...
                'FontName', 'Tahoma');
            if obj.Show_Labels
                xlabel(ax, 'X-Grid (mm)', 'FontName', 'Tahoma', 'Color', obj.XColor);
                ylabel(ax, 'Y-Grid (mm)', 'FontName', 'Tahoma', 'Color', obj.YColor);
            end
        end
        function setMontage(obj, montage)
            obj.Montage = montage;
        end
        function update(obj)
            % Get the axes
            ax = getAxes(obj);
            
            % Determine x-coordinates for electrodes
            if any(isnan(obj.XData))
                xdata = linspace(obj.XScale(1), obj.XScale(2), size(obj.YData,1));
                obj.XData = ((1:size(obj.YData,1))')./obj.Fs;
            else
                xdata = linspace(obj.XScale(1), obj.XScale(2), numel(obj.XData));
            end

            % Create extra lines as needed
            p = obj.EMG;
            nPlotLinesNeeded = size(obj.YData, 2);
            nPlotLinesHave = numel(p);
            for n = (nPlotLinesHave+1):nPlotLinesNeeded
                p(n) = matlab.graphics.chart.primitive.Line(...
                    'Parent', ax, ...
                    'SeriesIndex', n, ...
                    'Marker', 'x', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', [], ...
                    'LineWidth', obj.LineWidth, ...
                    'UserData', obj.XData);
                p(n).DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('T (s)', 'UserData'); 
            end
            
            tmp = obj.YData - nanmean(obj.YData, 1); %#ok<NANMEAN> 
            if numel(obj.Fc) == 2
                [b,a] = butter(4,(obj.Fc)./(obj.Fs / 2),'bandpass');
                ydata = filtfilt(b,a,tmp);
            elseif isempty(obj.Fc)
                ydata = tmp;
            else
                [b,a] = butter(2,(obj.Fc)./(obj.Fs / 2), 'high');
                ydata = filter(b,a,tmp);
            end
            

            ch = obj.Channel(obj.Enable);
            if isnan(obj.YScale)
                yscl = 6.5 * nanmedian(abs(ydata(:))); %#ok<NANMEDIAN> 
            else
                yscl = obj.YScale;
            end

            if ~any(isnan(obj.TrigData))
                blanked_samples = find(bitand(obj.TrigData, 2^obj.TriggerBit) == 0);
            else
                blanked_samples = [];
            end

            % Update the lines
            if obj.Color_By_RMS
                rms_epoch_mask = (obj.XData > obj.RMS_Epoch(1)) & (obj.XData <= obj.RMS_Epoch(2));
                if sum(rms_epoch_mask) == 0
                    warning("Coloring by RMS, but no samples were inside RMS_Epoch period; using all samples instead.");
                    rms_epoch_mask = true(size(obj.XData));
                end
                for n = 1:nPlotLinesNeeded
                    rms_val = min(max(rms(ydata(rms_epoch_mask & ~isnan(ydata(:,n)),n)), obj.RMS_Range(1)), obj.RMS_Range(2));
                    set(p(n), 'XData', xdata + obj.XGrid(ch(n)), ...
                        'YData', ydata(:,n)./yscl + obj.YGrid(ch(n)), ...
                        'Color', double(obj.CData_(rms_val))./255.0, ...
                        'UserData', obj.XData, ...
                        'MarkerIndices', blanked_samples);
                end
            else
                for n = 1:nPlotLinesNeeded
                    set(p(n), 'XData', xdata + obj.XGrid(ch(n)), ...
                        'YData', ydata(:,n)./yscl + obj.YGrid(ch(n)), ...
                        'UserData', obj.XData, ...
                        'MarkerIndices', blanked_samples);
                end
            end
            % Delete unneeded lines
            delete(p((nPlotLinesNeeded+1):numel(p)))
            obj.EMG = p(1:nPlotLinesNeeded);
            
        end
    end
end