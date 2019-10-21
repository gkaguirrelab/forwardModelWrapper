function outDirName = postprocessPRF(results, templateImage, outPath, workbenchPath, varargin)
% Produce maps from the analyzePRF results
%
% Syntax:
%  outDirName = postprocessPRF(results, templateImage, outPath, workbenchPath)
%
% Description:
%   This routine produces maps from the results structure returned by
%   analyzePRF.
%
% Inputs:
%   results               - Structure. Contains the results produced by
%                           the analyzePRF routine. 
%   templateImage         - Type dependent upon the nature of the input
%                           data
%   outPath               - String. Path to the directory in which ouput
%                           files are to be saved
%   workbenchPath         - String. path to workbench_command
%
% Optional key/value pairs:
%   dataFileType          - String. Select whether the data is volumetric
%                           or surface (CIFTI). Options: volumetric/cifti
%
% Outputs:
%   outDirName            - String. Where the maps were saved.


%% Parse inputs
p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('results', @isstruct);
p.addRequired('templateImage', @(x)(isobject(x) | isnumeric(x)));
p.addRequired('outPath', @isstr);
p.addRequired('workbenchPath', @isstr);

% Optional
p.addParameter('dataFileType', 'cifti', @isstr)

% Parse
p.parse(results, templateImage, outPath, workbenchPath, varargin{:})



%% Process the results

% For volumetric results, we need to reshape the data to have the dimensions defined by the
% templateImage
fieldsToSave = results.meta.mapField;
if strcmp(p.Results.dataFileType','volumetric')
    sizer = size(templateImage);
    for ii = 1:length(fieldsToSave)
        modifiedResults.(fieldsToSave{ii}) = ...
            reshape(results.(fieldsToSave{ii}),[sizer(1:end-1) 1]);
    end
end



%% Save output

% Save raw retinotopy results
save(fullfile(outPath,'forwardModel_results.mat'),'results')

% Create a maps directory
outDirName = fullfile(outPath,['maps_' p.Results.dataFileType]);
if ~exist(outDirName,'dir')
    mkdir(outDirName);
end

fieldsToSave = results.meta.mapField;
for ii = 1:length(fieldsToSave)
    outData = struct();
    switch p.Results.dataFileType
        case 'volumetric'
            fileName = fullfile(outDirName,[fieldsToSave{ii} '_map.nii.gz']);
            outData.vol = modifiedResults.(fieldsToSave{ii});
            outData.nframes = 1;
            MRIwrite(outData, fileName);
        case 'cifti'
            fileName = fullfile(outDirName,[fieldsToSave{ii} '_map.dtseries.nii']);
            outData = templateImage;
            outData.cdata = single(modifiedResults.(fieldsToSave{ii}));
            ciftisave(outData, fileName, workbenchPath)
        otherwise
            error('not a recognized dataFileType')
    end
end


end % Main function