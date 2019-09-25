function [data, stimulus, dataFileType, vxs, templateImage] = AnalzePRFPreprocess(workbench_path, inputDir, stimFileName, tempWorkingDir, dataFileType, varargin)

% This function prepares the data, stimulus and mask inputs for AnalyzePRF
%
% Syntax:
%  WrapperAnalyzePRF(stimFileName,dataFileName,tr,outpath)
%
% Inputs:
%   workbench_path        - String. path to workbench_command
%   inputDir              - String. Provides the data as a ICAfix zip  
%                           archive or a single volume or surface image
%   stimFileName          - String. A .mat file. Provides the apertures as   
%                           a cell vector of R x C x time. Values should be 
%                           in [0,1]. The number of time points can differ 
%                           across runs. 
%   tempWorkingDir        - String. This file is created for unzipping the 
%                           purposes. Deleted automatically when the
%                           function finishes.
%   dataFileType          - String. Select whether the data is volumetric
%                           or surface (CIFTI). Options: volumetric/cifti
%   prependDummyTRs       - String. If used. Adds the mean of the time 
%                           series for each voxel at the beginning of the 
%                           matrix until the data and stimulus matrix 
%                           lengths become equal. Options: 0 or 1. Def: 0
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

%% Parse inputs

p = inputParser; p.KeepUnmatched = true;
% Required
p.addRequired('workbench_path',@isstr);
p.addRequired('inputDir',@isstr);
p.addRequired('stimFileName',@isstr);
p.addRequired('tempWorkingDir',@isstr);
p.addRequired('dataFileType',@isstr);

% Optional
p.addParameter('maskFile', 'Na', @isstr)
p.addParameter('prependDummyTRs', "0", @isstr)

p.parse(workbench_path, inputDir, stimFileName, tempWorkingDir, dataFileType, varargin{:})

%% Process data

% Check the type of input: zip vs single acquisition
if inputDir(end-2:end) == "zip"
    % Create a working directory for unzipping
    mkdir(tempWorkingDir)
    unzip(inputDir, tempWorkingDir)
    d = dir(strcat(tempWorkingDir, '/*/MNINonLinear/Results'));
    d = d(~ismember({d.name},{'.','..'}));
    d(1) = [];
    runNumber = length(d);
    if dataFileType == "volumetric"
        for ii = 1:runNumber 
            rawName{ii} = strcat(d(ii).folder,'/', d(ii).name, '/', d(ii).name, '_', 'hp2000_clean.nii.gz');
            data{ii} = MRIread(rawName{ii});
            data{ii} = data{ii}.vol; 
            data{ii} = single(data{ii}); 
            data{ii} = reshape(data{ii}, [size(data{ii},1)*size(data{ii},2)*size(data{ii},3), size(data{ii},4)]);
            data{ii}(isnan(data{ii})) = 0; 
        end
    elseif dataFileType == "cifti"
        for ii = 1:runNumber 
            fprintf(strcat("Reading cifti number", ' ', num2str(ii), '\n'))
            rawName{ii} = strcat(d(ii).folder,'/', d(ii).name, '/', d(ii).name, '_', 'Atlas_hp2000_clean.dtseries.nii');
            %rawName{ii} = strcat(d(ii).folder,'/', d(ii).name, '/', d(ii).name, '_', 'Atlas.dtseries.nii');  %Foc hcpfunc
            temporary = ciftiopen(rawName{ii}, workbench_path);
            data{ii} = temporary.cdata; 
        end 
    else
        fprintf("Scan type is not valid")
    end

% This condition is used when a single acquisition is passed rather than a
% zip file
elseif p.Results.inputDir(end-2:end) == "nii" | inputDir(end-1:end) == "gz" 
    runNumber = 1;
    if p.Results.dataFileType == "volumetric"
        rawData = MRIread(p.Results.ataFileName);
        data = rawData.vol;
        data = single(data);
        data = reshape(data, [size(data,1)*size(data,2)*size(data,3), size(data,4)]); % Convert 4D to 2D
    elseif p.Results.dataFileType == "cifti"
        rawData = ciftiopen(p.Results.dataFileName, workbench_path);
        data = rawData.cdata;
    else
        fprintf("Scan type is not valid")
    end
else
    error('Unrecognized data input: Please either input an ICAfix zip archieve or a single volume/surface image')
end

%% Process stimulus 

% Load the stimulus, convert to single, and copy it to the other cells
% so that the cell size of the stimulus matches the cell size of the data
load(stimFileName,'stimulus');
stimulus = single(stimulus); 
dataLength = length(data);
stimLength = length(stimulus);
if dataLength ~= stimLength
    temporarystim = stimulus;
    stimulus = {};
    for celvar = 1:dataLength
        stimulus{celvar} = temporarystim;
    end
end

%% Process masks if specified

% Determine how many voxels to analyze from a mask 
if p.Results.maskFile ~= "Na"    
    if p.Results.dataFileType == "volumetric"
        rawMask = MRIread(p.Results.maskFileName); 
        mask = rawMask.vol;  
        mask = single(mask); 
        mask = reshape(mask, [size(mask,1)*size(mask,2)*size(mask,3),1]); 
        vxs = find(mask)';
        vxs = single(vxs);
    elseif p.Results.dataFileType == "cifti"
        rawMask = ciftiopen(p.Results.maskFileName, workbenc_path); 
        mask = rawMask.cdata;
        vxs = find(mask)';
        vxs = single(vxs);    
    end
% Analyze all voxels if no mask is specified     
else                                   
    is3d = size(data{1},4) > 1;
    if is3d
      %dimdata = 3;
      %dimtime = 4;
      xyzsize = sizefull(data{1},3);
    else
      %dimdata = 1;
      %dimtime = 2;
      xyzsize = size(data{1},1);
    end
    numvxs = prod(xyzsize);
    vxs = 1:numvxs;
end

% Check that the stimulus and data are of the same temporal length. If they
% are not same, but prependDummyTR command is issued, add the mean of the 
% time series for each voxel at the beginning of the matrix until the data 
% and stimulus matrix lengths become equal.

if inputDir(end-1:end) ~= "gz" | inputDir(end-2:end) ~= "nii" % This part does it for multiple runs
     for ii = 1:runNumber
         datasizes = size(data{ii});
         data_temporal_size = datasizes(2);
         stimsizes = size(stimulus{ii});
         stim_temporal_size = stimsizes(3);
         if data_temporal_size < stim_temporal_size
             if str2double(p.Results.prependDummyTRs) == 1
                 warning("prependDummyTR function is enabled")
                 difference = stim_temporal_size - data_temporal_size;
                 means_of_rows = mean(data, 2);
                 for change = 1:difference
                     data = horzcat(means_of_rows, data);
                 end
             else
                 errorMessage = "Sample lengths of the stimulus and data are not equal for the run number. Either resample your data or consider prependDummyTR option";
                 errorMessage = insertAfter(errorMessage, 'number', num2str(ii)); 
                 error(errorMessage)
             end
         end
     end  
else   %This one does it for single run
    datasizes = size(data{1});
    data_temporal_size = datasizes(2);
    stimsizes = size(stimulus{1});
    stim_temporal_size = stimsizes(3);
    if data_temporal_size < stim_temporal_size
        if str2double(p.Results.prependDummyTRs) == 1
            warning("prependDummyTR function is enabled")
            difference = stim_temporal_size - data_temporal_size;
            means_of_rows = mean(data, 2);
            for i = 1:difference
                data = horzcat(means_of_rows, data);
            end 
        else
            error("Sample lengths of the stimulus and data are not equal. Either resample your data or consider prependDummyTR option")
        end
    end
end

% Return a template image for saving maps later
templateImage = rawName{1};
%Delete the temporary work folder
rmdir(tempWorkingDir)