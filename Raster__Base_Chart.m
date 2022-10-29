classdef Raster__Base_Chart < Contour__Base_Chart
    % c = Raster__Base_Chart('TLim', seconds(n), 'Name', Value,...) - Shades in a square with an intensity color for every gridded data point.
    %
    % Methods:
    %   obj.append(ch, ts) - Append timestamp event (ts) to element-matched 
    %                  channel (column vector or scalar of channel indices) 
    
    properties (Access = protected)
        ch (:,1) double
        ts (:,1) datetime
        TLim (1,1) duration = seconds(5);
    end
    methods
        function obj = Raster__Base_Chart(varargin)
            obj@Contour__Base_Chart(varargin{:});
        end
        function append(obj, ch, ts)
            %APPEND  obj.append(ch, ts) - Append timestamp event(s) to channel(s).
            obj.ch = vertcat(obj.ch, ch);
            obj.ts = vertcat(obj.ts, ts);
            obj.update();
        end
        function redraw(obj)
            %REDRAW  obj.redraw() - Redraw the raster plot with new time.
            obj.update();
        end
        function updateTimescale(obj, tlim)
            %UPDATETIMESCALE  obj.updateTimescale(tlim) - Update timescale on which events are counted. 
            if ~isduration(tlim)
                tlim = seconds(abs(tlim));
            else
                tlim = abs(tlim);
            end
            obj.TLim = tlim;
            cb = getColorbar(obj);
            cb.Label.String = sprintf('N (past %s)', string(obj.TLim));
        end
    end
    methods(Access = protected)
        function setup(obj)
            setup@Contour__Base_Chart(obj);
            obj.EMG.CData = zeros(8, 8);
            cb = getColorbar(obj);
            cb.Label.String = sprintf('N (past %s)', string(obj.TLim));
        end
        function update(obj)
            tnow = datetime('now');
            idx = obj.ts < (tnow - obj.TLim);
            obj.ts(idx) = [];
            obj.ch(idx) = [];
            en_ch = obj.Channel(obj.Enable);
            cdata = obj.EMG.CData;
            for ii = 1:numel(en_ch)
                cdata(ii) = sum(obj.ch == en_ch(ii));
            end
            obj.CData = cdata;
            update@Contour__Base_Chart(obj);
        end
    end
end