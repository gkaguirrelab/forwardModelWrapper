function [stimulus, data, vxs, templateImage] = preprocessPRF(workbenchPath, funcZipPath, stimFilePath, tempDir, varargin)
% This function prepares the data, stimulus and mask inputs for AnalyzePRF
%
% Syntax:
%  [stimulus, data, vxs, templateImage] = preprocessPRF(workbench_path, funcZipPath, stimFilePath, tempDir)
%
% Description:
%   This routine takes the inputs as specified by (e.g.) a Flywheel gear
%   call and assembles the data and stimulus files for subsequent
%   processing by the pRF Wrapper stage.
%
% Inputs:
%   workbenchPath         - String. path to workbench_command
%   funcZipPath           - String. Provides the path to a zip archive that
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
%   maskFilePath          - String. Path to a mask file for the data.
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
%   stimulus              - Stimulus is a cell vector of R x C x time.
%                           If the cell size of input stimulus does not
%                           match the cell size of input data, the first
%                           cell is duplicated until they match. Be aware
%                           of this duplication if your stimulus time
%                           points are different accross runs.
%   data                  - If an ICAfix directory is specified, timeseries
%                           are extracted from all of the runs in the
%                           directory and reconstructed in a 1 x Run cell.
%                           Each image data is organized in those cells as
%                           voxels x time matrices. If a single file is
%                           specified, result is a similar matrix put in a
%                           1x1 cell.
%   vxs                   - Vector. Identifies the indices of the data to
%                           be analyzed. This is the implementation of a
%                           mask.
%   templateImage         - Type dependent upon the nature of the input
%                           data
%
% Examples:
%{
    [stimulus, data, vxs, templateImage] = AnalzePRFPreprocess(workbench_path, funcZipPath, stimFilePath, tempDir);
%}


%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('workbenchPath',@isstr);
p.addRequired('funcZipPath',@isstr);
p.addRequired('stimFilePath',@isstr);
p.addRequired('tempDir',@isstr);

% Optional
p.addParameter('verbose', '1', @isstr)
p.addParameter('maskFilePath', 'Na', @isstr)
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('dataFileType', 'cifti', @isstr)
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Parse
p.parse(workbenchPath, funcZipPath, stimFilePath, tempDir, varargin{:})

% Set up a logical verbose flag
verbose = strcmp(p.Results.verbose,'1');


%% Process data

% Ensure that we have been passed a zip file
if ~endsWith(funcZipPath,'zip')
    error('AnalyzePRFPreprocess:notAZip','fMRI data should be passed as the path to a zip archive');
end
if ~strcmp(p.Results.dataSourceType,'icafix')
    error('AnalyzePRFPreprocess:notICAFIX','We have only implemented processing of ICAFIX archives so far');
end

% Inform the user
if verbose
    fprintf('  Unzipping\n');
end

% Uncompress the zip archive
unzip(funcZipPath, tempDir)

% The ICA-FIX gear saves the output data within the MNINonLinear dir
acquisitionList = dir(strcat(tempDir, '/*/MNINonLinear/Results'));

% Remove the entries returned by dir that are 
acquisitionList = acquisitionList(~ismember({acquisitionList.name},{'.','..'}));

% Remove any entries that have a dot prefix, including the dir itself and the
% enclosing dir
acquisitionList = acquisitionList(...
    cellfun(@(x) ~startsWith(x,'.'),extractfield(acquisitionList,'name')) ...
    );

% Remove the ICAFIX concat dir
acquisitionList = acquisitionList(...
    cellfun(@(x) ~startsWith(x,'ICAFIX'),extractfield(acquisitionList,'name')) ...
    );

% Each entry left in funcZipPaths is a different fMRI acquisition
nAcquisitions = length(acquisitionList);

% Pre-allocate the data cell array
data = cell(1,nAcquisitions);

% Loop through the acquisitions
for ii = 1:nAcquisitions
    
    % The name of the acquisition, the loading, and the initial processing
    % varies for CIFIT and volumetric data
    switch p.Results.dataFileType
        case 'volumetric'
            rawName = strcat(acquisitionList(ii).folder, filesep, acquisitionList(ii).name, filesep, acquisitionList(ii).name, '_', 'hp2000_clean.nii.gz');
            thisAcqData = MRIread(rawName);
            % Check if this is the first acquisition. If so, retain an
            % example of the source data to be used as a template to format
            % the output files.
            if ii == 1
                templateImage = thisAcqData;
            end
            thisAcqData = thisAcqData.vol;
            thisAcqData = single(thisAcqData);
            thisAcqData = reshape(thisAcqData, [size(thisAcqData',1)*size(thisAcqData',2)*size(thisAcqData',3), size(thisAcqData',4)]);
            thisAcqData(isnan(thisAcqData)) = 0;
        case 'cifti'
            rawName = strcat(acquisitionList(ii).folder, filesep, acquisitionList(ii).name,filesep, acquisitionList(ii).name, '_', 'Atlas_hp2000_clean.dtseries.nii');
            thisAcqData = ciftiopen(rawName, workbenchPath);
            % Check if this is the first acquisition. If so, retain an
            % example of the source data to be used as a template to format
            % the output files.
            if ii == 1
                templateImage = thisAcqData;
                % Make the time dimension a singleton
                templateImage.cdata = templateImage.cdata(:,1);
            end
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
if strcmp(p.Results.averageAcquisitions,'1')
    
    % Alert the user
    if verbose
        fprintf('Averaging data acquisitions together\n')
    end
        
    % Check that all of the data cells have the same length
    if length(unique(cellfun(@(x) length(x),data))) > 1
            error('AnalyzePRFPreprocess:dataLengthDisagreement', 'Averaging of the acquisition data was requested, but the acquisitions are not of equal length');
    end

    % Perform the average
    meanData = zeros(size(data{1}));
    for ii=1:length(data)
        meanData = meanData + data{ii};
    end
    meanData = meanData ./ length(data);
    data = {meanData};
    clear meanData
    nAcquisitions = 1;
    
end


%% Process stimulus

% Alert the user
if verbose
    fprintf('Preparing the stimulus files\n')
end

% Load
load(stimFilePath,'stimulus');

% If the stimulus is just a single matrix, package it in a cell. This
% allows the user to supply a stimulus specification that is the matrix
% alone, and then have this apply to all acquisitions.
if ~iscell(stimulus)
    stimulus = {stimulus};
end

% Check the compatability of stimulus and data lengths
if length(stimulus)~=1 && length(stimulus)~=nAcquisitions
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

% Alert the user
if verbose
    fprintf('Checking for an optional mask file\n')
end

% If set to 'Na', then the entire data array is analyzed.
if strcmp(p.Results.maskFilePath,'Na')
    sizer = size(data{1});
    vxs = 1:prod(sizer(1:end-1));
else
    switch p.Results.dataFileType
        case 'volumetric'
            mask = MRIread(p.Results.maskFilePath);
            mask = mask.vol;
            mask = single(mask);
            mask = reshape(mask, [size(mask,1)*size(mask,2)*size(mask,3),1]);
            vxs = find(mask)';
            vxs = single(vxs);
        case 'cifti'
            rawMask = ciftiopen(p.Results.maskFilePath, workbenchPath);
            mask = rawMask.cdata;
            vxs = find(mask)';
            vxs = single(vxs);
        otherwise
            errorString = [p.Results.dataFileType ' is not a recognized dataFileType for this routine. Try, cifti or volumetric'];
            error('AnalyzePRFPreprocess:notICAFIX', errorString);
    end
end

end % Main Function
