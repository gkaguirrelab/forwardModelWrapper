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
%   flywheelFlag          - Logical. If set to true, the routine determines
%                           the profile to use and the number of available
%                           cores using a procedure that allows the system
%                           to make use of hyper-threaded, virtual cores
%                           within a Google Cloud virtual machine. 
%
% Outputs:
%   nWorkers              - Scalar. The number of workers available in the
%                           pool.
%

% Check if the flywheelFlag is set
if nargin==0
    flywheelFlag = false;
end

% Check if we are running within a Flywheel gear. If so, we will have been
% provided with a mlsettings profile that will have increased the maximum
% allowed number of workers in the parpool. This step is necessary as the
% default, "local" matlab profile does not recognize the multiple cores
% within a Google Cloud virtual machine as available workers, and thus will
% set the maximum allowed number of workers to 1.
if flywheelFlag
    fprintf('Starting the parpool with the flywheel profile\n');
    profile = parallel.importProfile(fullfile(filesep,'usr','flywheel.mlsettings'));
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
    command = 'cat /proc/cpuinfo |grep "cpu cores" | awk -F: ''{ num+=$2 } END{ print num }''';
    [~,nWorkers] = system(command);
    % In most cases, you would only want to use half of the available cores
    % on a machine at a time. If we are operating within Flywheel and thus
    % within a virtual machine, the only activity on the cores will be data
    % crunching for this process, so use them all.
    if flywheelFlag
        nWorkers = strtrim(nWorkers);
    else
        nWorkers = strtrim(num2str(str2num(nWorkers)/2));
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

% Report the number of cores that we have found.
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
        % Give a range of workers, so that if something has gone wrong with
        % the calculation of the number of available cores, the parpool
        % will still be able to limp into existence with half of the
        % requested cores.
        parpool(profile,[floor(nWorkers/2) nWorkers]);
    end
    
    % Check that we have successfully created a parpool and find out how
    % many workers we got.
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

