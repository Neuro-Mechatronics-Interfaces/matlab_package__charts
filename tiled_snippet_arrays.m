function fig = tiled_snippet_arrays()

pars = struct;
pars.Data = [];  % e.g. car_filt_data(:,1:64,:);  from UNI_DATA.mat file
pars.Data_File_Tag = 'UNI_DATA.mat';
pars.Experiment = ''; % e.g. 'Forrest_2022_11_08_A_24';
pars.Force_Save = false; % set true to force save even if fig handle output is requested (doesn't delete figure in this case).
pars.Grid_Layout = []; % e.g. [4, 1] to make one column of 4 plots.
pars.Input_Root = 'R:/NMLShare/generated_data/primate/DARPA_N3/N3_Patch/Forrest/Forrest_2022_11_08/interleaved';
pars.T = [10, 30]; % ms from stim-onset for epochs of interest
pars.Tag = % e.g. 'Run24_J_5_-13EMU_Biphasic-Anodal'
pars.Trial_Indices = []; % e.g. iPlot = [1,2,10,12];
pars.Type = @(varargin)Snippet_Array_8_8_L_Chart(varargin{:});
pars.Output_Figure_Root = 'fig/Spatial-Snippets';
pars.Position = [250 250 1000 350];

%% 
fig = figure('Name', 'Example Trials', ...
    'Color', 'w',...
    'Position',pars.Position);
L = tiledlayout(fig, 2, 2);
title(L, "Example Trials: Run24 | J_5 (-13 EMU)", 'FontName', 'Tahoma', 'Color', 'k');
subtitle(L, sprintf("(%3.1f-ms to %3.1f-ms after stim onset)", pars.T(1), pars.T(2)), 'FontName', 'Tahoma', 'Color', [0.65 0.65 0.65]);

iSample = (t.ms > pars.T(1)) & (t.ms <= pars.T(2));
for ii = iPlot
    nexttile(L);
    h = pars.Type('XData', t.ms(iSample), 'YData', pars.Data(iSample,:,ii), 'LineWidth', 1);
    title(h, sprintf('Stim-%02d', ii));
end

if nargout < 1
    if exist(pars.Output_Figure_Root, 'dir')==0
        mkdir(pars.Output_Figure_Root);
    end
    fname = sprintf('%s_%s_snippets', pars.Experiment, pars.Tag);
    saveas(fig, fullfile(pars.Output_Figure_Root, strcat(fname, '.png')));
    savefig(fig, fullfile(pars.Output_Figure_Root, fname));
    if ~pars.Force_Save
        delete(fig);
    end
end
end