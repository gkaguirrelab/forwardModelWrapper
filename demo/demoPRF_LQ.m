% demoPRF_LQ
%
% This routine downloads ICAFIX and hcp-struct data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to mainPRF
clear


%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'HERO_LZ';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Process one voxel that has a great fit
vxsPass = [21605];

% TR of the acquisition in seconds
tr = '0.8';

% The degree of polynomial to use to remove low-freq trends from the data
polyDeg = '5';

% Retino specific modelOpts
pixelsPerDegree = '5.1751';
screenMagnification = '0.91250';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '1';
averageVoxels = '0';
convertToPercentChange = '1';
typicalGain = '1';

%% Open the flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));


%% Download the stim file
projectID = '61f97f2fb3a174d109088334';
fileName = 'pRFStimulus_108x108x420.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath);


%% Download the mask file
projectID = '61f97f2fb3a174d109088334';
fileName = 'all_visual_areas_mask.nii';
maskFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,maskFilePath);

%% Download the struct file
analysisID = '62041b4bb58f355a99b83b9e';
fileName = 'HERO_LZ_hcpstruct.zip';
structZipPath = fullfile(saveDir,fileName);
fw.downloadOutputFromAnalysis(analysisID,fileName,structZipPath);



%% Download the functional data inputs
% To find these, get the ID for the session (which is in the URL of the web
% GUI, and then use this command to get a list of the analyses associated
% with that session, and then find the analysis ID the we want.
%
%{
    projectName = 'forwardModelWrapper';
    fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));
    sessionID = '62001b5f4aa0c13badb83a62';
    analysisList = fw.getSessionAnalyses(sessionID);
%}

% All the functional runs
analysisIDs = {'6238b488cc6ad31873026366','6238b4886b775c4cdd3f1064'};
fileNames{1} = {...
    'HERO_LZ_ICAFIX_multi_func-01_func-02_func-03_hcpicafix.zip',...
    };
fileNames{2} = {...
    'HERO_LZ_ICAFIX_multi_func-04_func-05_func-06_hcpicafix.zip',...
    };

% Download the files and assign the funcZipPath variables
fileIdx = 1;
for aa=1:length(analysisIDs)
    for ff = 1:length(fileNames{aa})
        tmpPath = fullfile(saveDir,fileNames{aa}{ff});
        if ~isfile(tmpPath)
            fw.downloadOutputFromAnalysis(analysisIDs{aa},fileNames{aa}{ff},tmpPath);
        end
        command = sprintf('funcZipPath%02d = tmpPath',fileIdx);
        eval(command);
        fileIdx=fileIdx+1;
    end
end

for ff=fileIdx:36
    tmpPath = 'Na';
    command = sprintf('funcZipPath%02d = tmpPath',ff);
    eval(command);
end


%% Additional settings

% Internal paths
workbenchPath = getpref(projectName,'wbCommand');
outPath = fullfile(scratchSaveDir,'v0','output');
if ~exist(outPath,'dir')
    mkdir(outPath);
end

% Path to the external python routine that converts map formats
externalMGZMakerPath = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','make_fsaverage.py');

% Path to the external python routine that converts map formats
externalCiftiToFreesurferPath = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','cifti_to_freesurfer.py');

% CIFTI atlases
standardMeshAtlasesFolder = fullfile(getpref('forwardModelWrapper','projectBaseDir'),'code','utilities','standard_mesh_atlases');

freesurferInstallationPath = '/Applications/freesurfer/';

workDir = outPath;


% Assemble the modelOpts
modelOpts = ['{' ...
    ' ''pixelsPerDegree'',' pixelsPerDegree ',' ...
    ' ''screenMagnification'',' screenMagnification ',' ...
    ' ''polyDeg'',' polyDeg ',' ...
    ' ''typicalGain'',' typicalGain ',' ...
    '}'];

%% Call the main routine
mainWrapper(funcZipPath01,funcZipPath02,funcZipPath03,funcZipPath04, ...
    funcZipPath05,funcZipPath06,funcZipPath07,funcZipPath08, ...
    funcZipPath09,funcZipPath10,funcZipPath11,funcZipPath12, ...
    funcZipPath13,funcZipPath14,funcZipPath15,funcZipPath16, ...
    funcZipPath17,funcZipPath18,funcZipPath19,funcZipPath20, ...
    funcZipPath21,funcZipPath22,funcZipPath23,funcZipPath24, ...
    funcZipPath25,funcZipPath26,funcZipPath27,funcZipPath28, ...
    funcZipPath29,funcZipPath30,funcZipPath31,funcZipPath32, ...
    funcZipPath33,funcZipPath34,funcZipPath35,funcZipPath36, ...
    stimFilePath, structZipPath, ...
    'maskFilePath',maskFilePath, ...
    'dataFileType','cifti', ...
    'dataSourceType','icafix', ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'convertToPercentChange',convertToPercentChange,...
    'tr',tr, ...
    'modelClass','prfTimeShift', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'externalCiftiToFreesurferPath', externalCiftiToFreesurferPath, ...
    'standardMeshAtlasesFolder', standardMeshAtlasesFolder, ...
    'freesurferInstallationPath', freesurferInstallationPath, ...
    'workDir', workDir, ...
    'outPath',outPath, ...
    'vxsPass', vxsPass);

