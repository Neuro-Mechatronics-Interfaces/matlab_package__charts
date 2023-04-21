function fig = tiled_snippet_arrays(SUBJ, YYYY, MM, DD, varargin)
%TILED_SNIPPET_ARRAYS  Create tiled snippet array figure(s)
%
% Syntax:
%   fig = tiled_snippet_arrays(SUBJ, YYYY, MM, DD, 'Name', value, ...);
%
% Example:
%   fig = tiled_snippet_arrays(SUBJ, YYYY, MM, DD, 'Data', x);
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
pars.Data = [];  % e.g. car_filt_data(:,1:64,:);  from UNI_DATA.mat file
pars.Data_File = 'UNI_DATA.mat';
pars.Experiment = ''; % e.g. "Forrest_2022_11_08_A_24";
pars.Fc = []; % Set to 2 elements for bandpass (i.e. [25, 400]). 1 element for highpass.
pars.Folder_Expression = 'Run*'; % For detecting folders in `interleaved` generated location
pars.Force_Save = false; % set true to force save even if fig handle output is requested (doesn't delete figure in this case).
pars.Grid_Layout = [4, 3]; % e.g. [4, 1] to make one column of 4 plots.
pars.Input_Root = 'R:/NMLShare/generated_data/primate/DARPA_N3/N3_Patch';
pars.T = [10, 30]; % ms from stim-onset for epochs of interest
pars.TS = [];
pars.Tag = ''; % e.g. "Run24_J_5_-13EMU_Biphasic-Anodal"
pars.Trial_Indices = []; % e.g. iPlot = [1,2,10,12];
pars.Type = @(varargin)charts.Snippet_Array_8_8_L_Chart(varargin{:});
pars.Output_Figure_Root = 'fig/Spatial-Snippets';
pars.Position = [250 250 875 650];
pars.RMS_Range = [0, 1];

if numel(varargin) > 0
    if isstruct(varargin{1})
        pars = varargin{1};
        varargin(1) = [];
    end
end

pars = utils.parse_parameters(pars, varargin{:});

if isempty(pars.Tag)
    if isempty(pars.Experiment)
        pars.Experiment = strjoin([string(SUBJ), num2str(YYYY, '%04d'), num2str(MM, '%02d'), num2str(DD, '%02d')], "_");
    end
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
            fig{ii} = charts.tiled_snippet_arrays(SUBJ, YYYY, MM, DD, pars, 'Tag', pars.Tag(ii));
        else
            charts.tiled_snippet_arrays(SUBJ, YYYY, MM, DD, pars, 'Tag', pars.Tag(ii));
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
            fig.(array) = charts.tiled_snippet_arrays(SUBJ, YYYY, MM, DD, pars, 'Array', array, 'Data', data(:,ch,:));
        else
            charts.tiled_snippet_arrays(SUBJ, YYYY, MM, DD, pars, 'Array', array, 'Data', data(:, ch, :));
        end
    end
    return;
end

if isempty(pars.Trial_Indices)
    if ~isempty(pars.Grid_Layout)
        k = pars.Grid_Layout(1)*pars.Grid_Layout(2);
    else
        k = size(pars.Data,3);
    end
    pars.Trial_Indices = randsample(size(pars.Data,3), k, false);
end
iPlot = sort(reshape(pars.Trial_Indices, 1, numel(pars.Trial_Indices)), 'ascend');

fig = figure(...
    'Name', 'Example Trials', ...
    'Color', 'w',...
    'Position',pars.Position);
if isempty(pars.Grid_Layout)
    L = tiledlayout(fig, 'flow');
else
    L = tiledlayout(fig, pars.Grid_Layout(1), pars.Grid_Layout(2));
end
meta = utils.pattern_name_to_metadata(pars.Tag);
title(L, sprintf("Example Trials: %s | %s (%d EMU)",meta.run, strcat(strrep(meta.optimizer, '_', '_{'), '}'), meta.stim.amplitude), ...
    'FontName', 'Tahoma', 'Color', 'k');
subtitle(L, sprintf("(Array-%s | %3.1f-ms to %3.1f-ms after stim onset)", pars.Array, pars.T(1), pars.T(2)), ...
    'FontName', 'Tahoma', 'Color', [0.65 0.65 0.65]);

iSample = (pars.TS.ms > pars.T(1)) & (pars.TS.ms <= pars.T(2));
for ii = iPlot
    nexttile(L);
    h = pars.Type('XData', pars.TS.ms(iSample), 'YData', pars.Data(iSample,:,ii), ...
        'Fc', pars.Fc, 'RMS_Range', pars.RMS_Range, ...
        'Color_By_RMS', true, 'LineWidth', 1);
    title(h, sprintf('Stim-%02d', ii));
end

if nargout < 1
    if exist(pars.Output_Figure_Root, 'dir')==0
        mkdir(pars.Output_Figure_Root);
    end
    fname = sprintf('%s_%s_%s_snippets', pars.Experiment, pars.Array, pars.Tag);
    saveas(fig, fullfile(pars.Output_Figure_Root, strcat(fname, '.png')));
    savefig(fig, fullfile(pars.Output_Figure_Root, fname));
    if ~pars.Force_Save
        delete(fig);
    end
end
end