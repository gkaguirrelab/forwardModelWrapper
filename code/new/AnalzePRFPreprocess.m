function [data, stimulus, vxs, templateImage] = AnalzePRFPreprocess(workbench_path, inputDataPath, stimFilePath, tempDir, varargin)
% This function prepares the data, stimulus and mask inputs for AnalyzePRF
%
% Syntax:
%  [data, stimulus, dataFileType, vxs, templateImage] = AnalzePRFPreprocess(workbench_path, inputDir, stimFileName, tempWorkingDir, dataFileType)
%
% Inputs:
%   workbench_path        - String. path to workbench_command
%   inputDataPath         - String. Provides the path to a zip archive that
%                           has been produced by either hcp-icafix or
%                           hcp-func.
%   stimFilePath          - String. Full path to a .mat file that contains
%                           the stimulus apertures, which is a cell vector
%                           of R x C x time. Values should be in [0,1]. The
%                           number of time points can differ across runs.
%                           The cell vector should either be of length n,
%                           where n is the number of acquisitions that are
%                           present in the input data zip file, or length
%                           1, in which case the cell vector is assumed to
%                           apply to every acquisition.
%   tempDir               - String. This file is created for unzipping the 
%                           purposes. Deleted automatically when the
%                           function finishes.
%
% Optional key/value pairs:
%   verbose               - String. Defaults to true
%   maskFile              - NEED THIS ENTRY
%   trimDummyStimTRs      - String. Defaults to 0. On occasion "dummy" TRs
%                           at the beginning of a scan are trimmed off by
%                           the pre-processing routine. This causes the
%                           stimulus and data lengths to be unequal. If
%                           this flag is set to true, the start of the
%                           stimulus is trimmed to match the data length.
%   dataFileType          - String. Select whether the data is volumetric
%                           or surface (CIFTI). Options: volumetric/cifti
%   dataSourceType        - String. The type of gear that produced the data
%                           zip file. This information is used to know how
%                           to find the data files within the zip archive.
%                           Valid options currently are: {'icafix'}
%   averageAcquisitions   - String. Logical.
%
% Outputs:
%   data                  - If an ICAfix directory is specified, timeseries 
%                           are extracted from all of the runs in the 
%                           directory and reconstructed in a 1 x Run cell.
%                           Each image data is organized in those cells as
%                           voxels x time matrices. If a single file is 
%                           specified, result is a similar matrix put in a
%                           1x1 cell.
%   stimulus              - Stimulus is a cell vector of R x C x time. 
%                           If the cell size of input stimulus does not 
%                           match the cell size of input data, the first 
%                           cell is duplicated until they match. Be aware 
%                           of this duplication if your stimulus time
%                           points are different accross runs.
%   vxs                   - 1 x k vector, where k is the product of the
%                           sizes of the non-time dimensions of the data
%                           files.
%   templateImage         - NEED THIS
%
% Examples:
%{
    [data, stimulus, dataFileType, vxs, templateImage] = AnalzePRFPreprocess(workbench_path, inputDir, stimFileName, tempWorkingDir, 'dataFileType', 'cifti')
%}

%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('workbench_path',@isstr);
p.addRequired('inputDataPath',@isstr);
p.addRequired('stimFilePath',@isstr);
p.addRequired('tempDir',@isstr);

% Optional
p.addParameter('verbose', '1', @isstr)
p.addParameter('maskFile', 'Na', @isstr)
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('dataFileType', 'cifti', @isstr)
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Parse
p.parse(workbench_path, inputDataPath, stimFilePath, tempDir, varargin{:})

% Set up a logical verbose flag
verbose = strcmp(p.Results.verbose,'1');


%% Process data

% Ensure that we have been passed a zip file
if ~endsWith(inputDataPaths,'zip')
    error('AnalyzePRFPreprocess:notAZip','fMRI data should be passed as the path to a zip archive');
end
if ~strcmp(p.Results.dataSourceType,'icafix')
    error('AnalyzePRFPreprocess:notICAFIX','We have only implemented processing of ICAFIX archives so far');
end

% Uncompress the zip archive
mkdir(tempDir)
unzip(inputDataPaths, tempDir)

% The ICA-FIX gear saves the output data within the MNINonLinear dir
dataPaths = dir(strcat(tempDir, '/*/MNINonLinear/Results'));

% Remove the entries returned by dir that are the dir itself and the
% enclosing dir
dataPaths = dataPaths(~ismember({dataPaths.name},{'.','..'}));

% ICAFIX has an initial (?) directory that has the average results across
% runs. We want to remove this here. Right now this seems like a "magic"
% assumption that may not generally hold.
dataPaths(1) = [];

% Each entry left in dataPaths is a different fMRI acquisition
nAcquisitions = length(dataPaths);

% Pre-allocate the data cell array
data = cell(1,nAcquisitions);

% Loop through the acquisitions
for ii = 1:nAcquisitions

    % The name of the acquisition, the loading, and the initial processing
    % varies for CIFIT and volumetric data
    switch p.Results.dataFileType
        case 'volumetric'
            rawName = strcat(dataPaths(ii).folder, filesep, dataPaths(ii).name, filesep, dataPaths(ii).name, '_', 'hp2000_clean.nii.gz');
            thisAcqData = MRIread(rawName);
            thisAcqData = thisAcqData.vol;
            thisAcqData = single(thisAcqData);
            thisAcqData = reshape(thisAcqData, [size(thisAcqData',1)*size(thisAcqData',2)*size(thisAcqData',3), size(thisAcqData',4)]);
            thisAcqData(isnan(thisAcqData)) = 0;
        case 'cifti'
            rawName = strcat(dataPaths(ii).folder, filesep, dataPaths(ii).name,filesep, dataPaths(ii).name, '_', 'Atlas_hp2000_clean.dtseries.nii');
            thisAcqData = ciftiopen(rawName{ii}, workbench_path);
            thisAcqData = thisAcqData.cdata;
        otherwise
            errorString = [p.Results.dataFileType ' is not a recognized dataFileType for this routine. Try, cifti or volumetric'];
            error('AnalyzePRFPreprocess:notICAFIX', errorString);
    end

    % Store the acquisition data in a cell array
    data{ii} = thisAcqData;
    
    % Alert the user
    if verbose
        outputString = ['Read acquisition ' num2str(ii) ' of ' num2str(nAcquisitions) ' -- ' rawName '\n'];
        fprintf(outputString)
    end
end


%% Average the acquisitions if requested
% If the experiment has collected multiple acquisitions of the same
% stimulus, then it may be desirable to average the fMRI data prior to
% model fitting. This has the property of increasing the informativeness of
% the R^2 fitting values, and making the analysis run more quickly.
if strmcmp(p.Results.averageAcquisitions,'1')
    
    % Alert the user
    if verbose
        fprintf('Averaging data acquisitions together\n')
    end
    
    %% OZZY TO ADD SOME AVERAGING CODE HERE
    % When done with this step, the data varibale should be a cell array
    % with only one entry.
end


%% Process stimulus 
load(stimFilePath,'stimulus');

% Sanity check the stimulus input
if ~iscell(stimulus)
	error('AnalyzePRFPreprocess:stimulusNotACell','The stimulus file must contain a cell array');
end
if length(stimulus)~=1 || length(stimulus)~=nAcquisitions
	error('AnalyzePRFPreprocess:stimulusWrongNumCells','The stimulus file must contain a cell array with one entry, or as many entries as data acquisitions');
end

% If the stimulus contains a single cell, then replicate this to be the
% same length as the data array
if length(stimulus)==1
    tmpStimulus = cell(1, nAcquisitions);
    tmpStimulus(:) = stimulus(1);
    stimulus = tmpStimulus;
end

% Check that the length of the stimulus matrices match the length of the
% data matricies. If prependDummyTR is set to true, pad the data.
for ii = 1:nAcquisitions
    dataTRs = size(data{ii},2);
    stimTRs = size(stimulus{ii},3);
    if dataTRs~=stimTRs
        if stimTRs>dataTRs && strcmp(p.Results.trimDummyStimTRs,'1')
            % Trim time points from the start of the stimulus to force it
            % to match the data
            thisStim = stimulus{ii};
            % thisStim is now a matrix of R x C x time. We snip off the
            % initial entries
            thisStim = thisStim(:,:,(stimTRs-dataTRs):end);
            stimulus{ii} = {thisStim};
            % Let the user know that some trimming went on!
            warnString = ['Stim file for acquisition ' num2str(ii) ' was trimmed at the start by ' num2str() ' TRs'];
            warning('AnalyzePRFPreprocess:stimulusTRTrim', warnString);

        else
            errorString = ['Acquisition ' num2str(ii) ' of ' num2str(nAcquisitions) ' has a mismatched number of TRs with its stimulus'];
            error('AnalyzePRFPreprocess:notICAFIX', errorString);
        end
    end
end


%% Process masks if specified
% The mask file is passed as an optional path to a mask file.

% If set to 'Na', then the entire data array is analyzed.
if strcmp(p.Results.maskFile,'Na')
    sizer = size(data{1});
    vxs = 1:prod(sizer(1:end-1));
else
    switch p.Results.dataFileType
        case 'volumetric'
            mask = MRIread(p.Results.maskFileName);
            mask = mask.vol;
            mask = single(mask);
            mask = reshape(mask, [size(mask,1)*size(mask,2)*size(mask,3),1]);
            vxs = find(mask)';
            vxs = single(vxs);
        case 'cifti'
            rawMask = ciftiopen(p.Results.maskFileName, workbenc_path);
            mask = rawMask.cdata;
            vxs = find(mask)';
            vxs = single(vxs);
        otherwise
            errorString = [p.Results.dataFileType ' is not a recognized dataFileType for this routine. Try, cifti or volumetric'];
            error('AnalyzePRFPreprocess:notICAFIX', errorString);
    end
end


%% FIX THIS
% Return a template image for saving maps later
templateImage = rawName{1};
%Delete the temporary work folder
rmdir(tempDir)