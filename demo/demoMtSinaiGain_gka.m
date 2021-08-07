% DEMO_eventGain
%
% This routine downloads ICAFIX and hcp-struct data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to mainPRF
clear




%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'HEROgka1';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end


% TR of the acquisition in seconds
tr = '1.0';

% The degree of polynomial to use to remove low-freq trends from the data
polyDeg = '13';

% Flag to average the acquisitions together before computing pRF
% parameters. This makes the operation faster.
averageAcquisitions = '0';
averageVoxels = '1';
convertToPercentChange = '1';
typicalGain = '1';

%% Open the flywheel object
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));


%% Download the stim file
projectID = '5ca7803af546b60029ef118e';
fileName = 'stimulus_HERO_gka1_allxAcq.mat';
stimFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,stimFilePath);


%% Download the mask file
projectID = '5ca7803af546b60029ef118e';
fileName = 'HEROgka1_inferred_varea.dtseries.nii';
maskFilePath = fullfile(saveDir,fileName);
fw.downloadFileFromProject(projectID,fileName,maskFilePath);


%% Download the functional data inputs
% To find these, get the ID for the session (which is in the URL of the web
% GUI, and then use this command to get a list of the analyses associated
% with that session, and then find the analysis ID the we want.
%
%{
    projectName = 'forwardModelWrapper';
    fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));
    sessionID = '5cab7166f546b6002af04970';
    analysisList = fw.getSessionAnalyses(sessionID);
%}

% All the functional runs
analysisID = '60e7dc32ee252d4df1e0779d';
fileNames = {...
    'task_sub-HEROgka1_ses-041416_task-LminusMA_run-01_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LminusMA_run-02_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LminusMA_run-03_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LminusMA_run-04_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LminusMA_run-05_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LminusMA_run-06_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LminusMB_run-01_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LminusMB_run-02_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LminusMB_run-03_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LminusMB_run-04_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LminusMB_run-05_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LminusMB_run-06_space-T1w_desc-preproc_bold_denoised_surfaces.zip' ...
    'task_sub-HEROgka1_ses-041416_task-SA_run-01_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-SA_run-02_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-SA_run-03_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-SA_run-04_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-SA_run-05_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-SA_run-06_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-SB_run-01_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-SB_run-02_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-SB_run-03_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-SB_run-04_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-SB_run-05_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-SB_run-06_space-T1w_desc-preproc_bold_denoised_surfaces.zip' ...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-01_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-02_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-03_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxA_run-04_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxA_run-05_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxA_run-06_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxB_run-01_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxB_run-02_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041416_task-LightFluxB_run-03_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxB_run-04_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxB_run-05_space-T1w_desc-preproc_bold_denoised_surfaces.zip',...
    'task_sub-HEROgka1_ses-041516_task-LightFluxB_run-06_space-T1w_desc-preproc_bold_denoised_surfaces.zip' ...
    };

% Download the files and assign the funcZipPath variables
for ff=1:36
    if ff<=length(fileNames)
        tmpPath = fullfile(saveDir,fileNames{ff});
        fw.downloadOutputFromAnalysis(analysisID,fileNames{ff},tmpPath);
        command = sprintf('funcZipPath%02d = tmpPath',ff);
        eval(command);
    else
        tmpPath = 'Na';
        command = sprintf('funcZipPath%02d = tmpPath',ff);
        eval(command);
    end
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

structZipPath = 'Na';

% Assemble the modelOpts
modelOpts = ['{' ...
    ' (polyDeg),' polyDeg ',' ...
    ' (typicalGain),' typicalGain ',' ...
    ' (stimLabels),{(f0Hz_LminusM_01),(f2Hz_LminusM_01),(f4Hz_LminusM_01),(f8Hz_LminusM_01),(f16Hz_LminusM_01),(f32Hz_LminusM_01),(f64Hz_LminusM_01),(attention_LminusM_01),(f0Hz_LminusM_02),(f2Hz_LminusM_02),(f4Hz_LminusM_02),(f8Hz_LminusM_02),(f16Hz_LminusM_02),(f32Hz_LminusM_02),(f64Hz_LminusM_02),(attention_LminusM_02),(f0Hz_LminusM_03),(f2Hz_LminusM_03),(f4Hz_LminusM_03),(f8Hz_LminusM_03),(f16Hz_LminusM_03),(f32Hz_LminusM_03),(f64Hz_LminusM_03),(attention_LminusM_03),(f0Hz_LminusM_04),(f2Hz_LminusM_04),(f4Hz_LminusM_04),(f8Hz_LminusM_04),(f16Hz_LminusM_04),(f32Hz_LminusM_04),(f64Hz_LminusM_04),(attention_LminusM_04),(f0Hz_LminusM_05),(f2Hz_LminusM_05),(f4Hz_LminusM_05),(f8Hz_LminusM_05),(f16Hz_LminusM_05),(f32Hz_LminusM_05),(f64Hz_LminusM_05),(attention_LminusM_05),(f0Hz_LminusM_06),(f2Hz_LminusM_06),(f4Hz_LminusM_06),(f8Hz_LminusM_06),(f16Hz_LminusM_06),(f32Hz_LminusM_06),(f64Hz_LminusM_06),(attention_LminusM_06),(f0Hz_LminusM_07),(f2Hz_LminusM_07),(f4Hz_LminusM_07),(f8Hz_LminusM_07),(f16Hz_LminusM_07),(f32Hz_LminusM_07),(f64Hz_LminusM_07),(attention_LminusM_07),(f0Hz_LminusM_08),(f2Hz_LminusM_08),(f4Hz_LminusM_08),(f8Hz_LminusM_08),(f16Hz_LminusM_08),(f32Hz_LminusM_08),(f64Hz_LminusM_08),(attention_LminusM_08),(f0Hz_LminusM_09),(f2Hz_LminusM_09),(f4Hz_LminusM_09),(f8Hz_LminusM_09),(f16Hz_LminusM_09),(f32Hz_LminusM_09),(f64Hz_LminusM_09),(attention_LminusM_09),(f0Hz_LminusM_10),(f2Hz_LminusM_10),(f4Hz_LminusM_10),(f8Hz_LminusM_10),(f16Hz_LminusM_10),(f32Hz_LminusM_10),(f64Hz_LminusM_10),(attention_LminusM_10),(f0Hz_LminusM_11),(f2Hz_LminusM_11),(f4Hz_LminusM_11),(f8Hz_LminusM_11),(f16Hz_LminusM_11),(f32Hz_LminusM_11),(f64Hz_LminusM_11),(attention_LminusM_11),(f0Hz_LminusM_12),(f2Hz_LminusM_12),(f4Hz_LminusM_12),(f8Hz_LminusM_12),(f16Hz_LminusM_12),(f32Hz_LminusM_12),(f64Hz_LminusM_12),(attention_LminusM_12),(f0Hz_S_01),(f2Hz_S_01),(f4Hz_S_01),(f8Hz_S_01),(f16Hz_S_01),(f32Hz_S_01),(f64Hz_S_01),(attention_S_01),(f0Hz_S_02),(f2Hz_S_02),(f4Hz_S_02),(f8Hz_S_02),(f16Hz_S_02),(f32Hz_S_02),(f64Hz_S_02),(attention_S_02),(f0Hz_S_03),(f2Hz_S_03),(f4Hz_S_03),(f8Hz_S_03),(f16Hz_S_03),(f32Hz_S_03),(f64Hz_S_03),(attention_S_03),(f0Hz_S_04),(f2Hz_S_04),(f4Hz_S_04),(f8Hz_S_04),(f16Hz_S_04),(f32Hz_S_04),(f64Hz_S_04),(attention_S_04),(f0Hz_S_05),(f2Hz_S_05),(f4Hz_S_05),(f8Hz_S_05),(f16Hz_S_05),(f32Hz_S_05),(f64Hz_S_05),(attention_S_05),(f0Hz_S_06),(f2Hz_S_06),(f4Hz_S_06),(f8Hz_S_06),(f16Hz_S_06),(f32Hz_S_06),(f64Hz_S_06),(attention_S_06),(f0Hz_S_07),(f2Hz_S_07),(f4Hz_S_07),(f8Hz_S_07),(f16Hz_S_07),(f32Hz_S_07),(f64Hz_S_07),(attention_S_07),(f0Hz_S_08),(f2Hz_S_08),(f4Hz_S_08),(f8Hz_S_08),(f16Hz_S_08),(f32Hz_S_08),(f64Hz_S_08),(attention_S_08),(f0Hz_S_09),(f2Hz_S_09),(f4Hz_S_09),(f8Hz_S_09),(f16Hz_S_09),(f32Hz_S_09),(f64Hz_S_09),(attention_S_09),(f0Hz_S_10),(f2Hz_S_10),(f4Hz_S_10),(f8Hz_S_10),(f16Hz_S_10),(f32Hz_S_10),(f64Hz_S_10),(attention_S_10),(f0Hz_S_11),(f2Hz_S_11),(f4Hz_S_11),(f8Hz_S_11),(f16Hz_S_11),(f32Hz_S_11),(f64Hz_S_11),(attention_S_11),(f0Hz_S_12),(f2Hz_S_12),(f4Hz_S_12),(f8Hz_S_12),(f16Hz_S_12),(f32Hz_S_12),(f64Hz_S_12),(attention_S_12),(f0Hz_LMS_01),(f2Hz_LMS_01),(f4Hz_LMS_01),(f8Hz_LMS_01),(f16Hz_LMS_01),(f32Hz_LMS_01),(f64Hz_LMS_01),(attention_LMS_01),(f0Hz_LMS_02),(f2Hz_LMS_02),(f4Hz_LMS_02),(f8Hz_LMS_02),(f16Hz_LMS_02),(f32Hz_LMS_02),(f64Hz_LMS_02),(attention_LMS_02),(f0Hz_LMS_03),(f2Hz_LMS_03),(f4Hz_LMS_03),(f8Hz_LMS_03),(f16Hz_LMS_03),(f32Hz_LMS_03),(f64Hz_LMS_03),(attention_LMS_03),(f0Hz_LMS_04),(f2Hz_LMS_04),(f4Hz_LMS_04),(f8Hz_LMS_04),(f16Hz_LMS_04),(f32Hz_LMS_04),(f64Hz_LMS_04),(attention_LMS_04),(f0Hz_LMS_05),(f2Hz_LMS_05),(f4Hz_LMS_05),(f8Hz_LMS_05),(f16Hz_LMS_05),(f32Hz_LMS_05),(f64Hz_LMS_05),(attention_LMS_05),(f0Hz_LMS_06),(f2Hz_LMS_06),(f4Hz_LMS_06),(f8Hz_LMS_06),(f16Hz_LMS_06),(f32Hz_LMS_06),(f64Hz_LMS_06),(attention_LMS_06),(f0Hz_LMS_07),(f2Hz_LMS_07),(f4Hz_LMS_07),(f8Hz_LMS_07),(f16Hz_LMS_07),(f32Hz_LMS_07),(f64Hz_LMS_07),(attention_LMS_07),(f0Hz_LMS_08),(f2Hz_LMS_08),(f4Hz_LMS_08),(f8Hz_LMS_08),(f16Hz_LMS_08),(f32Hz_LMS_08),(f64Hz_LMS_08),(attention_LMS_08),(f0Hz_LMS_09),(f2Hz_LMS_09),(f4Hz_LMS_09),(f8Hz_LMS_09),(f16Hz_LMS_09),(f32Hz_LMS_09),(f64Hz_LMS_09),(attention_LMS_09),(f0Hz_LMS_10),(f2Hz_LMS_10),(f4Hz_LMS_10),(f8Hz_LMS_10),(f16Hz_LMS_10),(f32Hz_LMS_10),(f64Hz_LMS_10),(attention_LMS_10),(f0Hz_LMS_11),(f2Hz_LMS_11),(f4Hz_LMS_11),(f8Hz_LMS_11),(f16Hz_LMS_11),(f32Hz_LMS_11),(f64Hz_LMS_11),(attention_LMS_11),(f0Hz_LMS_12),(f2Hz_LMS_12),(f4Hz_LMS_12),(f8Hz_LMS_12),(f16Hz_LMS_12),(f32Hz_LMS_12),(f64Hz_LMS_12),(attention_LMS_12)},' ...
    ' (confoundStimLabel),(attention), ' ...
    ' (avgAcqIdx),{ [1:336,2017:2352,4033:4368,6049:6384,8065:8400,10081:10416],[337:672,2353:2688,4369:4704,6385:6720,8401:8736,10417:10752],[673:1008,2689:3024,4705:5040,6721:7056,8737:9072,10753:11088],[1009:1344,3025:3360,5041:5376,7057:7392,9073:9408,11089:11424],[1345:1680,3361:3696,5377:5712,7393:7728,9409:9744,11425:11760],[1681:2016,3697:4032,5713:6048,7729:8064,9745:10080,11761:12096] } ' ...
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
    'dataSourceType','vol2surf', ...
    'averageAcquisitions',averageAcquisitions, ...
    'averageVoxels',averageVoxels, ...
    'convertToPercentChange',convertToPercentChange,...
    'tr',tr, ...
    'modelClass','mtSinai', ...
    'modelOpts',modelOpts, ...
    'Subject',subjectName,...
    'workbenchPath',workbenchPath, ...
    'externalMGZMakerPath', externalMGZMakerPath, ...
    'externalCiftiToFreesurferPath', externalCiftiToFreesurferPath, ...
    'standardMeshAtlasesFolder', standardMeshAtlasesFolder, ...
    'freesurferInstallationPath', freesurferInstallationPath, ...
    'workDir', workDir, ...
    'outPath',outPath);

