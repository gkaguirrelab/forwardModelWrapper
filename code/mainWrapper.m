function [hcpStructPath,subjectName,nativeSpaceDirPath,pseudoHemiDirPath] = mainWrapper(funcZipPath01, funcZipPath02, funcZipPath03, funcZipPath04, funcZipPath05, stimFilePath, structZipPath, varargin)
% Wrapper function for forwardModel, designed to used within Flywheel
%
% Syntax:
%  [hcpStructPath,subjectName,nativeSpaceDirPath,pseudoHemiDirPath] = mainWrapper(funcZipPath01, funcZipPath02, funcZipPath03, funcZipPath04, funcZipPath05, stimFilePath, structZipPath
%
% Description
%   This function is designed to be compiled and then called from within a
%   Flywheel gear to handle inputs and outputs associated with the
%   forwardModel toolbox. All inputs to the function are in the form of
%   strings, to support calling the function from the shell once it is
%   compiled.
%
% Inputs:
%   funcZipPath01,02,...  - String. Path to zip files that contain the
%                           fMRI data to be analyzed. These zip files are
%                           typically the output of the hcp-icafix or
%                           hcp-func gears. All five inputs are required,
%                           although 'Na' can be passed.
%   stimFilePath          - String. Path to a .mat file that contains the
%                           stimulus description.
%   structZipPath         - String. Path to a zip file that is the output
%                           of an hcp-struct gear operation.
%
% Optional key/value pairs:
%  'maskFilePath'         - String. Path to a file that defines a boolean
%                           mask to identify which voxels/vertices are to
%                           be analyzed. The form of the mask should match
%                           the dataFileType.
%  'payloadPath'          - String. Path to a .mat file that contains a
%                           cell array of variables to be passed to the
%                           model within forwardModel. Optional.
%  'dataFileType'         - String. Form of the data. {"volumetric",
%                           "cifti"}.
%  'Subject'              - String. The subject name or ID to be used to 
%                           label output files.
%  'dataSourceType'       - String. The type of gear that produced the fMRI
%                           data to be input. {"icafix","ldogfix"}.
%  'trimDummyStimTRs'     - String. Valid values of 1 or 0. If set to 1, 
%                           any mismatch in temporal support between the
%                           stimuli and data is handled by removing
%                           timepoints from the start of the stimulus. This
%                           is to handle the situation in which hcp-func
%                           has decided that some initial data time points
%                           have not reached steady state T1 levels and
%                           thus are "dummy" scans and are removed.
%  'averageAcquisitions'  - String. Valid values of 1 or 0. If set to 1, 
%                           the data acquisitions are averaged into a
%                           single timeseries per voxel/vertex. This is
%                           obviously only a valid operation if the same
%                           stimulus sequence was used for every
%                           acquisition.
%  'averageVoxels'        - String. Valid values of 1 or 0. If set to 1, 
%                           all time series (or the subset specified by the
%                           mask) are averaged prior to model fitting
%                           within the forwardModel routine.
%  'modelClass'           - String. The type of model to be fit within the
%                           forwardModel function.
%  'modelOpts'            - String. The model options to be passed to the
%                           model within forwardModel. This string is 
%                           a list of key-value pairs, and is formatted so
%                           that if passed to the eval() function, returns
%                           a cell array. Therefore, a valid string is 
%                           enclosed in curly brackets. Each key can be
%                           enclosed either in single quotes, or in open/
%                           close parens. The parens are replaced by single
%                           quotes.
%  'tr'                   - String. The TR of the fMRI data acquisition, in
%                           units of seconds.
%  'externalMGZMakerPath' - String. Path to the python function within this
%                           repo that converts the CIFTI files to native
%                           space MGZ files.
%  'RegName'              - String. The registration algorithm that was
%                           used to map subject native space to the atlas
%                           space used in HCP CIFTI files (32k_fs_LR). 
%                           Options here include 'FS' (which is the
%                           freesurfer cortical surface registration
%                           algorithm), 'MSMSULC' or 'MSMAll' (which are
%                           the recommended HCP pipeline approachs).
%  'workbenchPath'        - String. Path to a local copy of the Connectome
%                           Workbench codebase. Executables in the
%                           workbench are used to convert files.
%  'outPath'              - String. Path to the location where result files
%                           from the analysis should be saved.
%  'flywheelFlag'         - String. Valid values of 1 or 0. If set to 1,
%                           indicates that these functions are running as
%                           compiled code within a Flywheel gear, and
%                           presumably being executed within a Google Cloud
%                           Platform virtual machine. This information is
%                           used to control the manner in which the par
%                           pool is invoked so that the virtual cores
%                           that are created in a GCP VM are available for
%                           use by the par pool.
%  'vxsPass'              - Numeric. A vector of values that define the
%                           mask of voxels/vertices to be analyzed. This
%                           option over-rides the mask input, and is used
%                           exclusively by demo operations acting upon a
%                           non-compiled version of the code.
%
% Outputs:
%   hcpStructPath         - String.
%   subjectName           - String.
%   nativeSpaceDirPath    - String. Will be set to empty if there are no
%                           maps to convert from native to CIFTI space.
%   pseudoHemiDirPath     - String. Will be set to empty if there are no
%                           maps to convert from native to CIFTI space.
%

%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('funcZipPath01',@isstr);
p.addRequired('funcZipPath02',@isstr);
p.addRequired('funcZipPath03',@isstr);
p.addRequired('funcZipPath04',@isstr);
p.addRequired('funcZipPath05',@isstr);
p.addRequired('funcZipPath06',@isstr);
p.addRequired('funcZipPath07',@isstr);
p.addRequired('funcZipPath08',@isstr);
p.addRequired('funcZipPath09',@isstr);
p.addRequired('funcZipPath10',@isstr);
p.addRequired('stimFilePath',@isstr);
p.addRequired('structZipPath',@isstr);

% Optional inputs
p.addParameter('maskFilePath', 'Na', @isstr)
p.addParameter('payloadPath', 'Na', @isstr)

% Config options - multiple
p.addParameter('dataFileType', 'cifti', @isstr)
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('Subject', '00000', @isstr)

% Config options - pre-process
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Config options - forwardModel
p.addParameter('modelClass','prfTimeShift',@isstr);
p.addParameter('modelOpts','{}',@isstr);
p.addParameter('tr',[],@isstr);
p.addParameter('averageVoxels', '0', @isstr)

% Config options - convert to mgz
p.addParameter('externalMGZMakerPath', [], @isstr)
p.addParameter('RegName', 'FS', @isstr)

% Config options - make volumetric map gifs
p.addParameter('externalMapGifMakerPath', '/Users/aguirre/Documents/MATLAB/projects/forwardModelWrapper/code/plot_maps.py', @isstr)

% Internal paths
p.addParameter('workbenchPath', '', @isstr);
p.addParameter('outPath', '', @isstr);

% Control
p.addParameter('flywheelFlag', '0', @isstr);

% Config options - demo over-ride
p.addParameter('vxsPass', [], @isnumeric)


% Parse
p.parse(funcZipPath01, funcZipPath02, funcZipPath03, funcZipPath04, ...
    funcZipPath05, funcZipPath06, funcZipPath07, funcZipPath08, ...
    funcZipPath09, funcZipPath10, stimFilePath, structZipPath, varargin{:})


%% Assemble the funcZipPaths into a cell array
funcZipPath = {funcZipPath01, funcZipPath02, funcZipPath03, ...
    funcZipPath04, funcZipPath05, funcZipPath06, funcZipPath07, ...
    funcZipPath08, funcZipPath09, funcZipPath10 };

%% Parse the modelOpts string
% modelOpts may be passed in with parens substituted for single quotes. We
% replace those here.
modelOpts = p.Results.modelOpts;
modelOpts = strrep(modelOpts,'(','''');
modelOpts = strrep(modelOpts,')','''');


%% Preprocess
[stimulus, stimTime, data, vxs, templateImage] = ...
    handleInputs(p.Results.workbenchPath, funcZipPath, stimFilePath, ...
    'verbose',true,...      % Force verbose
    'maskFilePath',p.Results.maskFilePath, ...
    'trimDummyStimTRs',logical(str2double(p.Results.trimDummyStimTRs)), ...
    'dataFileType',p.Results.dataFileType, ...
    'dataSourceType',p.Results.dataSourceType, ...
    'averageAcquisitions',logical(str2double(p.Results.averageAcquisitions)) );

% If vxsPass has been defined (perhaps by the demo routine), substitute
% this value for vxs
if ~isempty(p.Results.vxsPass)
    vxs = p.Results.vxsPass;
end


%% Start the parpool
startParpool(logical(str2double(p.Results.flywheelFlag)));


%% forwardModel

% Load the payload
if ~strcmp(p.Results.payloadPath,'Na')
    load(p.Results.payloadPath,'payload');
else
    payload = {};
end

% Call the model
results = forwardModel(data,stimulus,str2double(p.Results.tr),...
    'stimTime', stimTime, ...
    'modelClass', p.Results.modelClass, ...
    'modelOpts', eval(modelOpts), ...
    'modelPayload', payload, ...
    'vxs', vxs, ...
    'averageVoxels', logical(str2double(p.Results.averageVoxels)),...
    'verbose',true);    % Force verbose

% Process and save the results
mapsPath = handleOutputs(...
    results, templateImage, p.Results.outPath, p.Results.Subject, ...
    p.Results.workbenchPath, 'dataFileType', p.Results.dataFileType);

% If forwardModel didn't generate any maps, then we are done. Set return
% variables to empty.
if isempty(mapsPath)
    hcpStructPath = '';
    subjectName = '';
    nativeSpaceDirPath = '';
    pseudoHemiDirPath = '';
    return
end

%% Save maps


% Create gifs of the volumetric maps
if strcmp(p.Results.dataFileType,'volumetric')

    % Uncompress the structZip into the dir that holds the zip. We do this
    % with a system call so that we can prevent over-writing a prior unzipped
    % version of the data (which can happen in demo mode).
    command = ['unzip -q -n ' structZipPath ' -d ' fileparts(structZipPath)];
    system(command);
    
    % Next steps depend on the dataSourceType
    switch p.Results.dataSourceType
        case 'ldogfix'
            % The anatomical image to be displayed is the in-vivo canine
            % template brain
            displayAnat = fullfile(fileparts(structZipPath),'Atlas','invivo','2x2x2resampled_invivoTemplate.nii.gz');
            threshold = '0.1'; 
            for mm = 1:length(results.meta.mapField)
                mapPath = fullfile(mapsPath,[p.Results.Subject '_' results.meta.mapField{mm} '_map.nii.gz']);
                gifOutStemName = [p.Results.Subject '_' results.meta.mapField{mm} '_statMap'];
                command =  ['python3 ' p.Results.externalMapGifMakerPath ' ' displayAnat ' ' mapPath ' ' threshold ' ' gifOutStemName ' ' p.Results.outPath];
                callErrorStatus = system(command);
                if callErrorStatus
                    warning('An error occurred during execution of the external Python function for map conversion');
                end
                
            end
    end
    
end



% If we are working with CIFTI files, convert the resulting maps to
% native-space MGZ images. These files can then serve as input to the
% neuropythy Bayesian fitting routine.
if strcmp(p.Results.dataFileType,'cifti')
    % Uncompress the structZip into the dir that holds the zip. We do this
    % with a system call so that we can prevent over-writing a prior unzipped
    % version of the data (which can happen in demo mode).
    command = ['unzip -q -n ' structZipPath ' -d ' fileparts(structZipPath)];
    system(command);
    
    % Find the directory that is produced by this unzip operation
    fileList = dir(fileparts(structZipPath));
    fileList = fileList(...
        cellfun(@(x) ~startsWith(x,'.'),extractfield(fileList,'name')) ...
        );
    fileList = fileList(cell2mat(extractfield(fileList,'isdir')));
    hcpStructPath = fullfile(fileList.folder,fileList.name);
    subjectName = fileList.name;
    
    % Create directories for the output files
    nativeSpaceDirPath = fullfile(p.Results.outPath, [p.Results.Subject '_maps_nativeMGZ']);
    if ~exist(nativeSpaceDirPath,'dir')
        mkdir(nativeSpaceDirPath);
    end
    pseudoHemiDirPath = fullfile(p.Results.outPath, [p.Results.Subject '_maps_nativeMGZ_pseudoHemisphere']);
    if ~exist(pseudoHemiDirPath,'dir')
        mkdir(pseudoHemiDirPath);
    end
    
    % Perform the call and report if an error occurred
    command =  ['python3 ' p.Results.externalMGZMakerPath ' ' mapsPath ' ' hcpStructPath ' ' p.Results.RegName ' ' nativeSpaceDirPath ' ' pseudoHemiDirPath ' ' p.Results.Subject];
    callErrorStatus = system(command);
    if callErrorStatus
        warning('An error occurred during execution of the external Python function for map conversion');
    end
    
    % Save rh map images
    surfPath = fullfile(hcpStructPath,'T1w',subjectName,'surf');
    for mm = 1:length(results.meta.mapField)
        dataPath = fullfile(nativeSpaceDirPath,['R_' p.Results.Subject '_' results.meta.mapField{mm} '_map.mgz']);
        fig = makeSurfMap(dataPath,surfPath, ...
            'mapScale',results.meta.mapScale{mm}, ...
            'mapLabel',results.meta.mapLabel{mm}, ...
            'mapBounds',results.meta.mapBounds{mm}, ...
            'hemisphere','rh','visible',false);
        plotFileName = fullfile(p.Results.outPath,['rh.' p.Results.Subject '_' results.meta.mapField{mm} '.png']);
        print(fig,plotFileName,'-dpng')
        close(fig);
    end
    
    % Save lh map images
    surfPath = fullfile(hcpStructPath,'T1w',subjectName,'surf');
    for mm = 1:length(results.meta.mapField)
        dataPath = fullfile(nativeSpaceDirPath,['L_' p.Results.Subject '_' results.meta.mapField{mm} '_map.mgz']);
        fig = makeSurfMap(dataPath,surfPath, ...
            'mapScale',results.meta.mapScale{mm}, ...
            'mapLabel',results.meta.mapLabel{mm}, ...
            'mapBounds',results.meta.mapBounds{mm}, ...
            'hemisphere','lh','visible',false);
        plotFileName = fullfile(p.Results.outPath,['lh.'  p.Results.Subject '_' results.meta.mapField{mm} '.png']);
        print(fig,plotFileName,'-dpng')
        close(fig);
    end
    
end % Handle CIFTI maps

end % Main function
