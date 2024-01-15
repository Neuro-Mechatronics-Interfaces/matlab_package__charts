function cfg = get_config(fname,montage)
%GET_CONFIG  Returns the config struct for this submodule.
%
% Syntax:
%   cfg = charts.get_config(); % Returns 'config.yaml' by default
%   cfg = charts.get_config(fname);
%   cfg = charts.get_config(fname,montage); % Gives struct for specific montage instead of all montages.
%
% See also: Contents
arguments
    fname {mustBeTextScalar} = 'config.yaml'
    montage {mustBeTextScalar} = ""
end
full_name = fullfile(fileparts(mfilename('fullpath')), fname);
cfg = charts.io.yaml.loadFile(full_name, "ConvertToArray", true);
if strlength(montage) > 0
    if ~isfield(cfg,montage)
        error("Montage '%s' is not a valid field of the configuration in %s. Check that the file is set up correctly or that the montage name is correct.", montage, fname);
    end
    cfg = cfg.(montage);
end
end