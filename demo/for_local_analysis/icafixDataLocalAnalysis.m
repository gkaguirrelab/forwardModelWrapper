function scratchSaveDir = icafixData(scratchDir, flywheelApi, subjectId)
setpref('flywheelMRSupport','flywheelScratchDir', scratchDir)
setpref('flywheelMRSupport','flywheelAPIKey', flywheelApi)

% Define a few variables
outputFileSuffix = '_hcpicafix.zip';
scratchSaveDir = getpref('flywheelMRSupport','flywheelScratchDir');

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
    struct('match', struct('subject0x2ecode', subjectId)), ...
    }} ...
    );
analyses = fw.search(searchStruct);

if length(analyses)~=1
    error('Search failed to find a unique analysis')
end

% Get the analysis object
thisAnalysis = fw.getAnalysis(analyses{1}.analysis.id);

% Find the file with the matching stem
analysisFileMatchIdx = cellfun(@(x) endsWith(x.name,outputFileSuffix),thisAnalysis.files);

% Get some more information about the analysis and define a saveStem
thisName = thisAnalysis.files{analysisFileMatchIdx}.name;
tmp = strsplit(thisName,outputFileSuffix);
saveStem = tmp{1};

% Inform the user
fprintf(['Downloading: ' thisName '\n']);
fprintf(['         to: ' scratchSaveDir '\n']);

% Download the matching file to the rootSaveDir. This can take a while
zipFileName = fw.downloadOutputFromAnalysis(thisAnalysis.id,thisName,fullfile(scratchSaveDir,thisName));

% Inform the user
fprintf('  Unzipping\n');

% Unzip the downloaded file; overwright existing; pipe the terminal
% output to dev/null
command = ['unzip -o -a ' zipFileName ' -d ' zipFileName '_unzip' devNull];
system(command);
end
