function pRFCompileWrapperLocalHook
% pRFCompileWrapperLocalHook
%
% For use with the ToolboxToolbox.  If you copy this into your
% ToolboxToolbox localToolboxHooks directory (by default,
% ~/localToolboxHooks) and delete "LocalHooksTemplate" from the filename,
% this will get run when you execute tbUse({'pRFCompileWrapperConfig'}) to set up for
% this project.  You then edit your local copy to match your local machine.
%
% The main thing that this does is define Matlab preferences that specify input and output
% directories.
%
% You will need to edit the project location and i/o directory locations
% to match what is true on your computer.

 
%% Define project
projectName = 'pRFCompileWrapper';
 

%% Clear out old preferences
if (ispref(projectName))
    rmpref(projectName);
end


%% Specify and save project location
projectBaseDir = tbLocateProject(projectName);
setpref(projectName,'projectBaseDir',projectBaseDir);


%% Set flywheel API key as a preference
flywheelAPIKey='Copy this value from flywheel and paste here';
setpref(projectName,'flywheelAPIKey',flywheelAPIKey);


%% Set the workbench command path
if ismac
setpref(projectName,'wbCommand','/Applications/workbench/bin_macosx64/wb_command');
end


%% Get the userID
[~, userID] = system('whoami');
userID = strtrim(userID);


%% Paths to store flywheel data and scratch space
if ismac
    % Code to run on Mac plaform
    setpref(projectName,'flywheelScratchDir','/tmp/flywheel');
    setpref(projectName,'flywheelRootDir',fullfile('/Users/',userID,'/Documents/flywheel'));
elseif isunix
    % Code to run on Linux plaform
    setpref(projectName,'flywheelScratchDir','/tmp/flywheel');
    setpref(projectName,'flywheelRootDir',fullfile('/home/',userID,'/Documents/flywheel'));
elseif ispc
    % Code to run on Windows platform
    warning('No supported for PC')
else
    disp('What are you using?')
end


end
