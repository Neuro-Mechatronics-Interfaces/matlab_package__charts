function cfg = get_config(fname)
%GET_CONFIG  Returns the config struct for this submodule.
%
% Syntax:
%   cfg = charts.get_config(); % Returns 'config.yaml' by default
%   cfg = charts.get_config(fname);
%
% See also: Contents

if nargin < 1
    fname = 'config.yaml';
end
full_name = fullfile(fileparts(mfilename('fullpath')), fname);
cfg = charts.io.yaml.loadFile(full_name, "ConvertToArray", true);
end