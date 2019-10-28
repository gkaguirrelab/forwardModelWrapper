function [ nWorkers ] = startParpool(flywheelFlag)
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

% Check if the flywheelFlag is set
if nargin==0
    flywheelFlag = false;
end

if flywheelFlag
    fprintf('Starting the parpool with the flywheel profile\n');
    profile = parallel.importProfile(fullfile('usr','flywheel.mlsettings'));
    parallel.defaultClusterProfile(profile);
else
    profile = 'local';
    fprintf('Starting the parpool with the local profile\n');
end

% We are going to be verbose
verbose = true;

% Silence the timezone warning
warningState = warning;
warning('off','MATLAB:datetime:NonstandardSystemTimeZoneFixed');
warning('off','MATLAB:datetime:NonstandardSystemTimeZone');

% Get the available cores
if ismac
    % Code to run on Mac plaform
    nWorkers = feature('numcores');
elseif isunix
    % Code to run on Linux plaform
    % "Siblings" is the number of virtual CPUs produced by hyperthreading.
    % Replace with "cpu cores" to obtain only the number of physical CPUs
    command = 'cat /proc/cpuinfo |grep "cpu cores" | awk -F: ''{ num+=$2 } END{ print num }''';
    [~,nWorkers] = system(command);
    if flywheelFlag
        nWorkers = strtrim(nWorkers);
    else
        nWorkers = strtrim(nWorkers/2);
    end
    % This function forces matlab to use this number of workers, even if
    % they are virtual
    nWorkers = str2double(nWorkers);
    maxNumCompThreads(nWorkers);
elseif ispc
    % Code to run on Windows platform
    warning('Not supported for PC')
else
    disp('What are you using?')
end
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
        parpool(profile,[floor(nWorkers/2) nWorkers]);
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

