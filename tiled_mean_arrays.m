function [fig,h] = tiled_mean_arrays(SUBJ, YYYY, MM, DD, varargin)
%TILED_MEAN_ARRAYS  Like tiled_snippet_arrays, but shows per-channel means.
%
% Syntax:
%   fig = tiled_mean_arrays(SUBJ, YYYY, MM, DD, 'Name', value, ...);
%
% Example:
%   fig = tiled_mean_arrays(SUBJ, YYYY, MM, DD, 'Data', x);
%
% Inputs:
%   SUBJ - Subject name (e.g. "Forrest")
%   YYYY - Year  (numeric)
%   MM   - Month (numeric)
%   DD   - Day (numeric)
%
% See name value options from pars struct below.

pars = struct;
pars.Array = "A";
pars.Auto_Keep_Figure = false; % Setting true doesn't delete figure even if output is not requested.
pars.Data = [];  % e.g. car_filt_data(:,1:64,:);  from UNI_DATA.mat file
pars.Data_File = 'UNI_DATA.mat';
pars.Experiment = ''; % e.g. "Forrest_2022_11_08_A_24";
pars.Fc = []; % Set to 2 elements for bandpass (i.e. [25, 400]). 1 element for highpass.
pars.Folder_Expression = 'Run*'; % For detecting folders in `interleaved` generated location
pars.Force_Save = false; % set true to force save even if fig handle output is requested (doesn't delete figure in this case).
pars.Input_Root = 'R:/NMLShare/generated_data/primate/DARPA_N3/N3_Patch';
pars.T = [10, 30]; % ms from stim-onset for epochs of interest
pars.TS = [];
pars.Tag = ''; % e.g. "Run24_J_5_-13EMU_Biphasic-Anodal"
pars.Tiled_Layout = [];  % Can send `tiled_layout` object and will use that as a container instead of making a new figure handle.
pars.Tiled_Location = {1, [1,1]};
pars.Type = @(varargin)charts.Snippet_Array_8_8_L_Chart(varargin{:});
pars.Output_Figure_Root = 'fig/Spatial-Averages';
pars.Position = [250 250 875 650];
pars.RMS_Range = [0, 1];
pars.RMS_Epoch = [10, 30]; % Epoch for computing RMS coloring
pars.Show_Labels = false; % Set to false to turn off "grid" markings
pars.Use_CAR = true;
pars.XColor = 'none';
pars.YColor = 'none';

if numel(varargin) > 0
    if isstruct(varargin{1})
        pars = varargin{1};
        varargin(1) = [];
    end
end

pars = utils.parse_parameters(pars, varargin{:});

if isempty(pars.Experiment)
    pars.Experiment = strjoin([string(SUBJ), num2str(YYYY, '%04d'), num2str(MM, '%02d'), num2str(DD, '%02d')], "_");
end

if isempty(pars.Tag)
    input_search = fullfile(pars.Input_Root, SUBJ, pars.Experiment, 'interleaved');
    F = dir(fullfile(input_search, pars.Folder_Expression));
    if isempty(F)
        error("No tagged folders found in generated_data at Input_Root (%s).", pars.Input_Root);
    end
    pars.Tag = string({F.name});
else
    pars.Tag = string(pars.Tag); 
end

if numel(pars.Tag) > 1
    if ~isempty(pars.Data)
        error("If supplying Data, then only send one data array at a time, with its matching 'Tag'.");
    end
    if nargout > 0
        fig = cell(size(pars.Tag));
    end
    for ii = 1:numel(pars.Tag)
        if nargout > 0
            fig{ii} = charts.tiled_mean_arrays(SUBJ, YYYY, MM, DD, pars, 'Tag', pars.Tag(ii));
        else
            charts.tiled_mean_arrays(SUBJ, YYYY, MM, DD, pars, 'Tag', pars.Tag(ii));
        end
    end
    return;
end

if isempty(pars.Data)
    in = load(fullfile(pars.Input_Root, SUBJ, pars.Experiment, 'interleaved', pars.Tag, pars.Data_File),...
        'car_filt_data', 'filt_data', 't');
    if pars.Use_CAR
        data = in.car_filt_data;
    else
        data = in.filt_data;
    end
    if isempty(pars.TS)
        pars.TS = in.t;
    end
    
    if nargout > 0
        if isempty(pars.Array)
            pars.Array = ["A", "B"];
            fig = struct('A', gobjects(1), 'B', gobjects(2));
        else
            fig = struct;
            for ii = 1:numel(pars.Array)
                fig.(pars.Array(ii)) = gobjects(1);
            end
        end
    else
        if isempty(pars.Array)
            pars.Array = ["A", "B"];
        end
    end
    for array = pars.Array
        if strcmpi(array, "A")
            ch = 1:64;
        else
            ch = 65:128;
        end
        if nargout > 0
            fig.(array) = charts.tiled_mean_arrays(SUBJ, YYYY, MM, DD, pars, 'Array', array, 'Data', data(:,ch,:));
        else
            charts.tiled_mean_arrays(SUBJ, YYYY, MM, DD, pars, 'Array', array, 'Data', data(:, ch, :));
        end
    end
    return;
end

if isempty(pars.Tiled_Layout)
    fig = figure(...
        'Name', 'Example Trials', ...
        'Color', 'w',...
        'Position',pars.Position);
    L = tiledlayout(fig,1,1);
    meta = utils.pattern_name_to_metadata(pars.Tag);
    title(L, sprintf("Trial Mean (N = %d): %s | %s (%d EMU)",...
        size(pars.Data,3),meta.run, strcat(strrep(meta.optimizer, '_', '_{'), '}'), meta.stim.amplitude), ...
        'FontName', 'Tahoma', 'Color', 'k');
    subtitle(L, sprintf("(Array-%s | %3.1f-ms to %3.1f-ms after stim onset)", pars.Array, pars.T(1), pars.T(2)), ...
        'FontName', 'Tahoma', 'Color', [0.65 0.65 0.65]);
else
    fig = pars.Tiled_Layout.Parent;
    L = pars.Tiled_Layout;
end

iSample = (pars.TS.ms > pars.T(1)) & (pars.TS.ms <= pars.T(2));
switch numel(pars.Fc)
    case 0
        tmp = pars.Data;
    case 1
        [b,a] = butter(1, pars.Fc ./ 2000, "high");
        tmp = filter(b,a,pars.Data,[],1);
    case 2
        [b,a] = butter(1, pars.Fc ./ 2000, "bandpass");
        tmp = filter(b,a,pars.Data,[],1);
end
mu = mean(abs(tmp(iSample,:,:)), 3);
nexttile(L, pars.Tiled_Location{:});
h = pars.Type(L, 'XData', pars.TS.ms(iSample), 'YData', mu, ...
        'Fc', [], 'RMS_Range', pars.RMS_Range, 'RMS_Epoch', pars.RMS_Epoch, 'Show_Labels', pars.Show_Labels, ...
        'Color_By_RMS', true, 'LineWidth', 1, 'XColor',pars.XColor,'YColor',pars.YColor);

if ((nargout < 1) || pars.Force_Save) && ~pars.Auto_Keep_Figure
    if exist(pars.Output_Figure_Root, 'dir')==0
        mkdir(pars.Output_Figure_Root);
    end
    fname = sprintf('%s_%s_%s_averages', pars.Experiment, pars.Array, pars.Tag);
    saveas(fig, fullfile(pars.Output_Figure_Root, strcat(fname, '.png')));
    savefig(fig, fullfile(pars.Output_Figure_Root, fname));
    if ~pars.Force_Save
        delete(fig);
    end
end
end