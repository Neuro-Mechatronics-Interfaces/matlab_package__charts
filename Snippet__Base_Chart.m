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
        CData (1,64) double = NaN
        Color_By_RMS (1,1) logical = true
        Enable (1,64) logical = true(1,64)
        FlipXGrid (1,1) logical = false;
        FlipYGrid (1,1) logical = false;
        HUnits (1,1) string {mustBeTextScalar} = "s";
        VUnits (1,1) string {mustBeTextScalar} = "\muV";
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
        EMG_ (:,1) matlab.graphics.chart.primitive.Line
        Outline_ (1,1) matlab.graphics.chart.primitive.Line
        VScale_ (1,1) matlab.graphics.chart.primitive.Line
        VSText_ (1,1) matlab.graphics.primitive.Text
        HScale_ (1,1) matlab.graphics.chart.primitive.Line
        HSText_ (1,1) matlab.graphics.primitive.Text
    end
    properties(SetAccess = protected, GetAccess = public)
        YScale (1, 1) double = nan % If non-nan then this used to scale vertical bounds
        XScale (1, 2) double = nan(1,2)% Scaling to constrain line object "spatial" bounds (mm)
        XGrid (:, 8) double = nan(8,8) % X-coordinate centers (mm)
        YGrid (:, 8) double = nan(8,8) % Y-coordinate centers (mm)
        Outline (:,2) double = [];
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
        function subtitle(obj, varargin)
            ax = getAxes(obj);
            subtitle(ax, varargin{:});
        end
        function xlabel(obj, varargin)
            ax = getAxes(obj);
            xlabel(ax, varargin{:});
        end
        function xlim(obj, limits)
            arguments
                obj
                limits (1,2) double
            end
            ax = getAxes(obj);
            xlim(ax, limits);
        end
        function ylabel(obj, varargin)
            ax = getAxes(obj);
            ylabel(ax, varargin{:});
        end
        function colorbar(obj, varargin)
            ax = getAxes(obj);
            c = colorbar(ax, varargin{:});
            title(c, sprintf('RMS (%s)', obj.VUnits), 'FontName','Tahoma','Color','k');
        end
        function ylim(obj, limits)
            arguments
                obj
                limits (1,2) double
            end
            ax = getAxes(obj);
            ylim(ax, limits);
        end
        function setVerticalScale(obj, yscale)
            arguments
                obj
                yscale (1,1) double
            end
            obj.YScale = yscale;

            obj.update();
        end
        function setHorizontalScale(obj, xleft, xright)
            arguments
                obj
                xleft (1,1) double
                xright (1,1) double
            end
            obj.XScale = [xleft, xright];
            obj.update();
        end
        function setFigurePosition(obj, xywh)
            arguments
                obj
                xywh (1,4) double % [X, Y, Width, Height] (pixels)
            end
            obj.Parent.Position = xywh;
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
            ax.CLim = obj.RMS_Range;
            
            c_rms = cm.map('rosette');
            c_rms(1,:) = [64 64 64]; % Make the first entry grey;
            obj.CData_ = cm.cmap(obj.RMS_Range, c_rms);

            % Determine x-coordinates for electrodes
            if any(isnan(obj.XData))
                xdata = linspace(obj.XScale(1), obj.XScale(2), size(obj.YData,1));
                obj.XData = ((1:size(obj.YData,1))')./obj.Fs;
            else
                xdata = linspace(obj.XScale(1), obj.XScale(2), numel(obj.XData));
            end
            if obj.FlipXGrid
                xsclg = -1;
            else
                xsclg = 1;
            end
            if obj.FlipYGrid
                ysclg = -1;
            else
                ysclg = 1;
            end

            % Create extra lines as needed
            p = obj.EMG_;
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
            end
            
%             tmp = obj.YData - nanmean(obj.YData, 1); %#ok<NANMEAN> 
            if numel(obj.Fc) == 2
                [b,a] = butter(4,(obj.Fc)./(obj.Fs / 2),'bandpass');
                ydata = filtfilt(b,a,obj.YData);
            elseif isempty(obj.Fc)
                ydata = obj.YData;
            else
                [b,a] = butter(2,(obj.Fc)./(obj.Fs / 2), 'high');
                ydata = filter(b,a,obj.YData);
            end
            

            ch = obj.Channel(obj.Enable);
            if isnan(obj.YScale)
                obj.YScale = 6.5 * nanmedian(abs(ydata(:))); %#ok<NANMEDIAN> 
            end
            yscl = obj.YScale./(obj.XScale(2)-obj.XScale(1));

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
                    if isnan(obj.CData(n))
                        rms_val = min(max(rms(ydata(rms_epoch_mask & ~isnan(ydata(:,n)),n)), obj.RMS_Range(1)), obj.RMS_Range(2));
                    else
                        rms_val = min(max(obj.CData(n),obj.RMS_Range(1)),obj.RMS_Range(2));
                    end
                    set(p(n), ...
                        'XData', xdata + obj.XGrid(ch(n))*xsclg, ...
                        'YData', ydata(:,n)./yscl + obj.YGrid(ch(n))*ysclg, ...
                        'Color', double(obj.CData_(rms_val))./255.0, ...
                        'UserData', obj.XData, ...
                        'MarkerIndices', blanked_samples);
                    p(n).DataTipTemplate.DataTipRows = [dataTipTextRow(sprintf('T (%s)',obj.HUnits), 'UserData'); dataTipTextRow(sprintf('EMG (%s)',obj.VUnits), ydata(:,n))]; 
                end
            else
                for n = 1:nPlotLinesNeeded
                    set(p(n), ...
                        'XData', xdata + obj.XGrid(ch(n))*xsclg, ...
                        'YData', ydata(:,n)./yscl + obj.YGrid(ch(n))*ysclg, ...
                        'UserData', obj.XData, ...
                        'MarkerIndices', blanked_samples);
                    if ~isnan(obj.CData(n))
                        cval = min(max(obj.CData(n),obj.RMS_Range(1)),obj.RMS_Range(2));
                        set(p(n), 'Color', double(obj.CData_(cval))./255.0);
                    end
                    p(n).DataTipTemplate.DataTipRows = [dataTipTextRow(sprintf('T (%s)',obj.HUnits), 'UserData'); dataTipTextRow(sprintf('EMG (%s)',obj.VUnits), ydata(:,n))]; 
                end
            end
            % Delete unneeded lines
            delete(p((nPlotLinesNeeded+1):numel(p)))
            obj.EMG_ = p(1:nPlotLinesNeeded);
            
            delete(obj.Outline_);
            obj.Outline_ = matlab.graphics.chart.primitive.Line('Parent', ax, 'XData', obj.Outline(:,1).*xsclg, 'YData', obj.Outline(:,2).*ysclg,'Color','k','LineWidth',1.25);
            obj.Outline_.Annotation.LegendInformation.IconDisplayStyle = 'off';

            delete(obj.HScale_);
            delete(obj.HSText_);
            obj.HScale_ = matlab.graphics.chart.primitive.Line('Parent', ax, 'XData', (obj.Outline(1,1)+2.*xsclg)+([-xsclg*(obj.XScale(2)-obj.XScale(1)),0]), 'YData', ones(1,2).*(obj.Outline(1,2)-4.5.*ysclg),'Color','k','LineWidth',1.25);
            obj.HScale_.Annotation.LegendInformation.IconDisplayStyle = 'off';
            obj.HSText_ = matlab.graphics.primitive.Text('Parent', ax, 'String', sprintf('%d %s',round(obj.XData(end)-obj.XData(1)),obj.HUnits), 'Position', [-xsclg*(obj.XScale(2)-obj.XScale(1))+obj.Outline(1,1)+3.5.*xsclg,obj.Outline(1,2)-4.5.*ysclg],'Color','k','FontName','Tahoma','VerticalAlignment','top','HorizontalAlignment','left');

            delete(obj.VScale_);
            delete(obj.VSText_);
            obj.VScale_ = matlab.graphics.chart.primitive.Line('Parent', ax, 'XData', ones(1,2).*(obj.Outline(1,1)+2.*xsclg-xsclg*(obj.XScale(2)-obj.XScale(1))), 'YData', (obj.Outline(1,2)-4.5.*ysclg) + ([0, ysclg*(obj.XScale(2)-obj.XScale(1))]),'Color','k','LineWidth',1.25);
            obj.VScale_.Annotation.LegendInformation.IconDisplayStyle = 'off';
            obj.VSText_ = matlab.graphics.primitive.Text('Parent', ax, 'String', sprintf('%d%s',round(obj.YScale),obj.VUnits), 'Position', [obj.Outline(1,1)+2.*xsclg-xsclg*(obj.XScale(2)-obj.XScale(1)),obj.Outline(1,2)-4.5.*ysclg+0.5*ysclg*yscl/obj.YScale],'Color','k','FontName','Tahoma','VerticalAlignment','bottom','HorizontalAlignment','right');

        end
    end
end