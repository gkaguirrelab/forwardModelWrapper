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
%   verbose               - Logical. Defaults to true
%   maskFilePath          - String. Path to a mask file for the data.
%   trimDummyStimTRs      - Logical. Defaults to false. On occasion "dummy"
%                           TRs at the beginning of a scan are trimmed off
%                           by the pre-processing routine. This causes the
%                           stimulus and data lengths to be unequal. If
%                           this flag is set to true, the start of the
%                           stimulus is trimmed to match the data length.
%   dataFileType          - String. Select whether the data is volumetric
%                           or surface (CIFTI). Options: volumetric/cifti
%   dataSourceType        - String. The type of gear that produced the data
%                           zip file. This information is used to know how
%                           to find the data files within the zip archive.
%                           Valid options currently are: {'icafix'}
%   averageAcquisitions   - Logical.
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
p.addParameter('verbose', true, @islogical)
p.addParameter('maskFilePath', 'Na', @isstr)
p.addParameter('trimDummyStimTRs', false, @islogical)
p.addParameter('dataFileType', 'cifti', @isstr)
p.addParameter('dataSourceType', 'icafix', @isstr)
p.addParameter('averageAcquisitions', true, @islogical)
p.addParameter('cleanUpZips', true, @islogical)

% Parse
p.parse(workbenchPath, funcZipPath, stimFilePath, varargin{:})

% Set up a logical flags
verbose = p.Results.verbose;
trimDummyStimTRs = p.Results.trimDummyStimTRs;
averageAcquisitions = p.Results.averageAcquisitions;

%% Check inputs

% Strip out entries in the funcZipPath that are "Na"
funcZipPath = funcZipPath(~strcmp(funcZipPath,'Na'));

% Ensure that we have been passed a zip file
for jj=1:length(funcZipPath)
    if ~endsWith(funcZipPath{jj},'zip')
        error('handleInputs:notAZip','fMRI data should be passed as the path to a zip archive');
    end
end


%% Loop over entries in funcZipPath
data = {};
totalAcquisitions = 0;

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
    
    % Find the files, which vary in name and location by dataSourceType
    switch p.Results.dataSourceType
        case 'icafix'
            
            % The ICA-FIX gear saves the output data within the MNINonLinear dir
            acquisitionList = dir(fullfile(zipDir,'*','MNINonLinear','Results'));
            
            % Remove the entries returned by dir that are
            acquisitionList = acquisitionList(~ismember({acquisitionList.name},{'.','..'}));
            
            % Remove any entries that have a dot prefix, including the dir itself and the
            % enclosing dir
            acquisitionList = acquisitionList(...
                cellfun(@(x) ~startsWith(x,'.'),extractfield(acquisitionList,'name')) ...
                );
            
            % Find the ICAFIX concat dir
            icaFixConcatDir = acquisitionList(cellfun(@(x) startsWith(x,'ICAFIX'),extractfield(acquisitionList,'name')));
            
            % Remove the ICAFIX concat dir from the acquisition list
            acquisitionList = acquisitionList(...
                cellfun(@(x) ~startsWith(x,'ICAFIX'),extractfield(acquisitionList,'name')) ...
                );
            
            % Each entry left in funcZipPaths is a different fMRI acquisition
            nAcquisitions = length(acquisitionList);
            
            % We want to respect the order of the acquisitions as they were given
            % to ICAFIX, so that this order can be matched to the order of a
            % stimulus array. To do so, we examine the name of the ICAFIX concat
            % dir and determine the order in which the acquisitions are listed
            for ii=1:nAcquisitions
                namePos(ii) = strfind(icaFixConcatDir.name,acquisitionList(ii).name);
            end
            [~,acqIdxOrder] = sort(namePos);
            
        case {'ldogfix','ldogFix'}
            
            % The ldogFix gear saves the acquisitions in a shallow
            % directory structure
            acquisitionList = dir(fullfile(zipDir,'*','*.nii.gz'));
            
            % Some housekeeping variables
           nAcquisitions = length(acquisitionList);            
           acqIdxOrder = 1:nAcquisitions;
            
        case 'vol2surf'
            
            % vol2surf gear saves the acquisitions in a cifti folder
            % located in the main directory
            acquisitionList = dir(fullfile(zipDir,'ciftiFSLR_32k','*.nii'));
            nAcquisitions = length(acquisitionList); 
            acqIdxOrder = 1:nAcquisitions;
            
    end
    
    % Loop through the acquisitions
    for nn = 1:nAcquisitions
        
        % Load the acquisitions in the specified order (this is mostly
        % relevant for ICAFIX outputs)
        ii = acqIdxOrder(nn);
        
        % Get the name of the acquisition
        switch p.Results.dataSourceType
            case 'icafix'
                switch p.Results.dataFileType
                    case 'volumetric'
                        rawName = strcat(acquisitionList(ii).folder, filesep, acquisitionList(ii).name, filesep, acquisitionList(ii).name, '_', 'hp2000_clean.nii.gz');
                    case 'cifti'
                        rawName = strcat(acquisitionList(ii).folder, filesep, acquisitionList(ii).name,filesep, acquisitionList(ii).name, '_', 'Atlas_hp2000_clean.dtseries.nii');
                end
            case {'ldogfix','ldogFix'}
                rawName = fullfile(acquisitionList(ii).folder,acquisitionList(ii).name);
            case 'vol2surf'
                rawName = fullfile(acquisitionList(ii).folder,acquisitionList(ii).name);
        end
        
        % Load the data, dependent upon dataFileType
        switch p.Results.dataFileType
            case 'volumetric'
                thisAcqData = MRIread(rawName);
                % Check if this is the first acquisition. If so, retain an
                % example of the source data to be used as a template to format
                % the output files.
                if nn == 1
                    templateImage = thisAcqData;
                    templateImage.vol = squeeze(templateImage.vol(:,:,:,1));
                    templateImage.nframes = 1;
                end
                thisAcqData = thisAcqData.vol;
                thisAcqData = single(thisAcqData);
                thisAcqData = reshape(thisAcqData, [size(thisAcqData,1)*size(thisAcqData,2)*size(thisAcqData,3), size(thisAcqData,4)]);
                thisAcqData(isnan(thisAcqData)) = 0;
            case 'cifti'
                thisAcqData = ciftiopen(rawName, workbenchPath);
                % Check if this is the first acquisition. If so, retain an
                % example of the source data to be used as a template to format
                % the output files.
                if nn == 1
                    templateImage = thisAcqData;
                    % Make the time dimension a singleton
                    templateImage.cdata = templateImage.cdata(:,1);
                end
                thisAcqData = thisAcqData.cdata;
            otherwise
                errorString = [p.Results.dataFileType ' is not a recognized dataFileType for this routine. Try, cifti or volumetric'];
                error('handleInputs:invalidDataFileType', errorString);
        end
        
        % Increment the total number of acquisitions
        totalAcquisitions = totalAcquisitions + 1;
        
        % Store the acquisition data in a cell array
        data{totalAcquisitions} = thisAcqData;
        
        % Alert the user
        if verbose
            outputString = ['Read acquisition ' num2str(nn) ' of ' num2str(nAcquisitions) ' -- ' rawName '\n'];
            fprintf(outputString)
        end
    end % Loop over acquisitions within a funcZip file
    
    % Delete the temporary directory that contains the unpacked zip
    % contents
    if p.Results.cleanUpZips
        command = ['rm -r ' zipDir];
        system(command);
    end
    
end % Loop over entries in funcZipPath


%% Average the acquisitions if requested
% If the experiment has collected multiple acquisitions of the same
% stimulus, then it may be desirable to average the fMRI data prior to
% model fitting. This has the property of increasing the informativeness of
% the R^2 fitting values, and making the analysis run more quickly.
if averageAcquisitions
    
    % Alert the user
    if verbose
        fprintf('Averaging data acquisitions.\n')
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
    fprintf('Preparing the stimulus files.\n')
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

% Place the stimTime into cell format if not already there.
if ~iscell(stimTime)
    stimTime = {stimTime};
end

% Force all stimulus entries to be of type double
for ii = 1:length(stimulus)
    stimulus{ii}=double(stimulus{ii});
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
        stimTRs = size(stimulus{ii},ndims(stimulus{ii}));
        if dataTRs~=stimTRs
            if stimTRs>dataTRs && trimDummyStimTRs
                % Trim time points from the start of the stimulus to force
                % it to match the data
                thisStim = stimulus{ii};
                % Be sensitive to the number of dimensions in the stimulus
                switch ndims(thisStim)
                    case 2
                        thisStim = thisStim(:,(stimTRs-dataTRs):end);
                    case 3
                        thisStim = thisStim(:,:,(stimTRs-dataTRs):end);
                    case 4
                        thisStim = thisStim(:,:,:,(stimTRs-dataTRs):end);
                end
                stimulus{ii} = {thisStim};
                % Let the user know that some trimming went on!
                warnString = ['Stim file for acquisition ' num2str(ii) ' was trimmed at the start by ' num2str() ' TRs'];
                warning('handleInputs:stimulusTRTrim', warnString);
                
            else
                errorString = ['Acquisition ' num2str(ii) ' of ' num2str(totalAcquisitions) ' has ' num2str(dataTRs) ' TRs, but the stimulus has ' num2str(stimTRs) ' TRs'];
                error('handleInputs:mismatchTRs', errorString);
            end
        end
    end
end


%% Process masks if specified
% The mask file is passed as an optional path to a mask file.

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
    
    % Alert the user
    if verbose
        fprintf(['Found a mask with ' num2str(length(vxs)) ' voxels/vertices\n']);
    end
end

end % Main Function
