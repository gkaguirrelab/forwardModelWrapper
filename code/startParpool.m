function [ nWorkers ] = startParpool( )
% Open and configure the parpool
%
% Syntax:
%  [ nWorkers ] = startParpool( nWorkers, verbosity )
%
% Description:
%   This routine opens the parpool (if it does not currently exist) 
%   and returns the number of available workers.
%
% Inputs:
%   nWorkers              - Scalar. The number of workers requested.
%   verbose               - Boolean. Defaults to false if not passed.
%
% Outputs:
%   nWorkers              - Scalar. The number of workers available.
%

% We are going to be verbose
verbose = true;

% Silence the timezone warning
warningState = warning;
warning('off','MATLAB:datetime:NonstandardSystemTimeZoneFixed');
warning('off','MATLAB:datetime:NonstandardSystemTimeZone');

% Get the available cores
nWorkers = feature('numcores');
fprintf(['Number of cores available: ' num2str(nWorkers) '\n']);

% If a parallel pool does not exist, attempt to create one
poolObj = gcp('nocreate');
if isempty(poolObj)
    if verbose
        tic
        fprintf(['Opening parallel pool. Started ' char(datetime('now')) '\n']);
    end
    if isempty(nWorkers)
        parpool;
    else
        parpool(nWorkers);
    end
    poolObj = gcp;
    if isempty(poolObj)
        nWorkers=0;
    else
        nWorkers = poolObj.NumWorkers;
    end
    if verbose
        toc
        fprintf('\n');
    end
else
    nWorkers = poolObj.NumWorkers;
end

% Restore the warning state
warning(warningState);

end % function -- startParpool

