% DEMO pRF analysis
%
% This routine downloads a set of ICAFIX data from flywheel and then
% submits the files to pRF analysis.


% Which subject to process?
subjectName = 'TOME_3021';

% Define a few variables
outputFileSuffix = '_hcpicafix.zip';
wbCommand = getpref('flywheelMRSupport','wbCommand');
scratchSaveDir = getpref('flywheelMRSupport','flywheelScratchDir');

% Create the save dir if it does not exist
if ~exist(scratchSaveDir,'dir')
    mkdir(scratchSaveDir);
end

% This is the dev-null path for Mac OSX
devNull = ' >/dev/null';

% Create a flywheel object
fw = flywheel.Flywheel(getpref('flywheelMRSupport','flywheelAPIKey'));

% The ica-fix results for the RETINO data for one subject
searchStruct = struct(...
    'returnType', 'analysis', ...
    'filters', {{...
    struct('match', struct('analysis0x2elabel', 'hcp-icafix')), ...
    struct('match', struct('analysis0x2elabel', 'RETINO')), ...
    struct('match', struct('project0x2elabel', 'tome')), ...
    struct('match', struct('subject0x2ecode', subjectName)), ...
    }} ...
    );
analyses = fw.search(searchStruct);

% We should only find one analysis result for this search
if length(analyses)~=1
    error('Search failed to find a unique analysis')
end

% Get the analysis object
thisAnalysis = fw.getAnalysis(analyses{1}.analysis.id);

% Find the file with the matching stem
analysisFileMatchIdx = cellfun(@(x) endsWith(x.name,outputFileSuffix),thisAnalysis.files);

% Get some more information about the analysis and define a saveStem
thisName = thisAnalysis.files{analysisFileMatchIdx}.name;
saveName = fullfile(scratchSaveDir,thisName);

% If the file has not already been downloaded, get it
if ~exist(saveName,'file')
    
    % Inform the user
    fprintf(['Downloading: ' thisName '\n']);
    fprintf(['         to: ' scratchSaveDir '\n']);
    
    % Download the matching file to the rootSaveDir. This can take a while
    fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,saveName);
    
    % Inform the user
    fprintf('  Unzipping\n');
    
    % Unzip the downloaded file; overwright existing; pipe the terminal
    % output to dev/null
    command = ['unzip -o -a ' saveName ' -d ' saveName '_unzip' devNull];
    system(command);
    
end

% Find the acquisition directories within the unzipped file directory
subjectID = thisAnalysis.job.config.config.Subject;
acquisitionDir = fullfile([saveName '_unzip'],subjectID,'MNINonLinear','Results');
acquisitionList = dir(acquisitionDir);

% Remove the dir itself, the enclosing dir, and the ICAFIX concat dir
acquisitionList = acquisitionList(3:end);
acquisitionList = acquisitionList(...
    cellfun(@(x) ~startsWith(x,'ICAFIX'),extractfield(acquisitionList,'name')) ...
    );

% Identify the CIFTI files
ciftiPathList = {};
for ii=1:length(acquisitionList)
    path = fullfile(acquisitionDir,acquisitionList(ii).name);
    name = dir(fullfile(path,'*_clean.dtseries.nii'));
    ciftiPathList(ii) = {fullfile(path,name.name)};
end

% Identify the NIFTI files
niftiPathList = {};
for ii=1:length(acquisitionList)
    path = fullfile(acquisitionDir,acquisitionList(ii).name);
    name = dir(fullfile(path,'*_clean.nii.gz'));
    niftiPathList(ii) = {fullfile(path,name.name)};
end

% Set the path to the stimulus; assume it is in the same directory as this
% script
demoDir = mfilename('fullpath');
demoDir = demoDir(1:find(demoDir == filesep, 1, 'last'));
stimFileName = fullfile(demoDir,'pRFStimulus_108x108x420.mat');

% Set the TR to 0.8 seconds
tr = 0.8;

% Call the pRF analysis wrapper
fprintf('  Calling the pRF routine\n');
% call wrapper here


