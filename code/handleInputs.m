function [stimulus, stimTime, data, vxs, templateImage] = handleInputs(workbenchPath, funcZipPath, stimFilePath, varargin)
% This function prepares the data, stimulus and mask inputs for AnalyzePRF
%
% Syntax:
%  [stimulus, stimTime, data, vxs, templateImage] = handleInputs(workbenchPath, funcZipPath, stimFilePath)
%
% Description:
%   This routine takes the inputs as specified by (e.g.) a Flywheel gear
%   call and assembles the data and stimulus files for subsequent
%   processing by forwardModel.
%
% Inputs:
%   workbenchPath         - String. path to workbench_command
%   funcZipPath           - Cell array of strings. Provides the paths to
%                           zip archives that has been produced by either
%                           hcp-icafix or hcp-func. May contain entries
%                           that are "Na", which will be ignored.
%   stimFilePath          - String. Full path to a .mat file that contains
%                           the stimulus descriptions. This is a matrix in
%                           which the last dimension is the time domain of
%                           the stimulus. The precise form of the stimulus
%                           matrix is determined by the particular model
%                           that is to be fit. A typical form is [x y st],
%                           which provides the property of the stimulus in
%                           the x-y domain of the stimulus display over
%                           stimulus time. The input may also be a cell
%                           array of such matrices. If the stimulus time
%                           (st) is different in length than the data time
%                           (t), the mat file must also include a valid
%                           stimTime variable that provides the temporal
%                           support for each stimulus matrix in units of
%                           seconds.
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
%   stimulus              - Stimulus is a cell vector of one or more
%                           matrices. If the cell size of input stimulus
%                           does not match the cell size of input data, the
%                           first cell is duplicated until they match. Be
%                           aware of this duplication if your stimulus time
%                           points are different accross runs.
%   stimTime              - Cell array of vectors that provide the temporal
%                           support for the stimulus matrices.
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



%% Parse inputs
p = inputParser; p.KeepUnmatched = false;

% Required
p.addRequired('workbenchPath',@isstr);
p.addRequired('funcZipPath',@iscell);
p.addRequired('stimFilePath',@isstr);

% Optional
p.addParameter('verbose', '1', @isstr)
p.addParameter('maskFilePath', 'Na', @isstr)
p.addParameter('trimDummyStimTRs', '0', @isstr)
p.addParameter('dataFileType', 'cifti', @isstr)
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('averageAcquisitions', '0', @isstr)

% Parse
p.parse(workbenchPath, funcZipPath, stimFilePath, varargin{:})

% Set up a logical verbose flag
verbose = strcmp(p.Results.verbose,'1');


%% Check inputs

% Strip out entries in the funcZipPath that are "Na"
funcZipPath = funcZipPath(~strcmp(funcZipPath,'Na'));

% Ensure that we have been passed a zip file
for jj=1:length(funcZipPath)
    if ~endsWith(funcZipPath{jj},'zip')
        error('handleInputs:notAZip','fMRI data should be passed as the path to a zip archive');
    end
end
if ~strcmp(p.Results.dataSourceType,'icafix')
    error('handleInputs:notICAFIX','We have only implemented processing of ICAFIX archives so far');
end


%% Loop over entries in funcZipPath
data = {};
totalAcquisitions = 1;

for jj=1:length(funcZipPath)
    
    % Inform the user
    if verbose
        fprintf('  Unzipping funcZip\n');
    end
    
    % Create a temp directory to hold the zip file output
    zipDir = fullfile(fileparts(funcZipPath{jj}),tempname('.'));
    mkdir(zipDir)
    
    % Uncompress the zip archive into the zipDir.
    command = ['unzip -q -n ' funcZipPath{jj} ' -d ' zipDir];
    system(command);
    
    % Find the files
    
    % The ICA-FIX gear saves the output data within the MNINonLinear dir
    acquisitionList = dir(fullfile(zipDir,'*','MNINonLinear','Results'));
    
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
                error('handleInputs:notICAFIX', errorString);
        end
        
        % Store the acquisition data in a cell array
        data{totalAcquisitions} = thisAcqData;
        
        % Increment the total number of acquisitions
        totalAcquisitions = totalAcquisitions + 1;
                       
        % Alert the user
        if verbose
            outputString = ['Read acquisition ' num2str(ii) ' of ' num2str(nAcquisitions) ' -- ' rawName '\n'];
            fprintf(outputString)
        end
    end % Loop over acquisitions within a funcZip file
    
    % Delete the temporary directory that contains the unpacked zip
    % contents
    command = ['rm -r ' zipDir];
    %system(command);
    
end % Loop over entries in funcZipPath



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
            error('handleInputs:dataLengthDisagreement', 'Averaging of the acquisition data was requested, but the acquisitions are not of equal length');
    end

    % Perform the average
    meanData = zeros(size(data{1}));
    for ii=1:length(data)
        meanData = meanData + data{ii};
    end
    meanData = meanData ./ length(data);
    data = {meanData};
    clear meanData
    totalAcquisitions = 1;
    
end


%% Process stimulus

% Alert the user
if verbose
    fprintf('Preparing the stimulus files\n')
end

% Load the stimulus, and potentially stimTime, variables
warningState = warning;
warning('off','MATLAB:load:variableNotFound');        
load(stimFilePath,'stimulus','stimTime');
warning(warningState);
if ~exist('stimTime','var')
    stimTime = {};
end

% If the stimulus is just a single matrix, package it in a cell. This
% allows the user to supply a stimulus specification that is the matrix
% alone, and then have this apply to all acquisitions.
if ~iscell(stimulus)
    stimulus = {stimulus};
end
if ~iscell(stimTime)
    stimTime = {stimTime};
end

% Check the compatability of stimulus and data lengths
if length(stimulus)~=1 && length(stimulus)~=totalAcquisitions
    error('handleInputs:stimulusWrongNumCells','The stimulus file must contain a cell array with one entry, or as many entries as data acquisitions');
end

% If the stimTime is not empty, check its compatibility
if ~isempty(stimTime)
    if length(stimTime)~=1 && length(stimTime)~=totalAcquisitions
        error('handleInputs:stimulusWrongNumCells','The stimulus file must contain a cell array with one entry, or as many entries as data acquisitions');
    end
end


% If the stimulus and stimTime contains a single cell, then replicate this
% to be the same length as the data array
if length(stimulus)==1
    tmpStimulus = cell(1, totalAcquisitions);
    tmpStimulus(:) = stimulus(1);
    stimulus = tmpStimulus;
end
if length(stimTime)==1
    tmpStimTime = cell(1, totalAcquisitions);
    tmpStimTime(:) = stimTime(1);
    stimTime = tmpStimTime;
end

% If the stimTime variable is empty, check that the length of the stimulus
% matrices match the length of the data matricies. If prependDummyTR is set
% to true, pad the data.
if isempty(stimTime)
    for ii = 1:totalAcquisitions
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
                warning('handleInputs:stimulusTRTrim', warnString);
                
            else
                errorString = ['Acquisition ' num2str(ii) ' of ' num2str(totalAcquisitions) ' has a mismatched number of TRs with its stimulus'];
                error('handleInputs:mismatchTRs', errorString);
            end
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
            error('handleInputs:notICAFIX', errorString);
    end
end

end % Main Function
