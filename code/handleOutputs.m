function outDirName = handleOutputs(results, templateImage, outPath, Subject, workbenchPath, varargin)
% Produce maps from the analyzePRF results
%
% Syntax:
%  outDirName = handleOutputs(results, templateImage, outPath, workbenchPath)
%
% Description:
%   This routine produces maps from the results structure returned by
%   forwardModel.
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
p.addRequired('Subject', @isstr);
p.addRequired('workbenchPath', @isstr);

% Optional
p.addParameter('dataFileType', 'cifti', @isstr)

% Parse
p.parse(results, templateImage, outPath, Subject, workbenchPath, varargin{:})




%% Save the results figures
figFields = fieldnames(results.figures);
if ~isempty(figFields)
    for ii = 1:length(figFields)
        figHandle = struct2handle(results.figures.(figFields{ii}).hgS_070000,0,'convert');
        plotFileName = fullfile(p.Results.outPath,[Subject '_' figFields{ii}]);
        print(figHandle,plotFileName,results.figures.(figFields{ii}).format,'-fillpage')
        close(figHandle);
    end
end


%% Process the results

% For volumetric results, we need to reshape the data to have the dimensions defined by the
% templateImage
fieldsToSave = results.meta.mapField;
if strcmp(p.Results.dataFileType,'volumetric')
    sizer = size(templateImage);
    for ii = 1:length(fieldsToSave)
        results.(fieldsToSave{ii}) = ...
            reshape(results.(fieldsToSave{ii}),[sizer(1:end-1) 1]);
    end
end



%% Save output

% Save raw retinotopy results
save(fullfile(outPath,[Subject '_forwardModel_results.mat']),'results')

% Create a maps directory
outDirName = fullfile(outPath,[Subject '_maps_' p.Results.dataFileType]);
if ~exist(outDirName,'dir')
    mkdir(outDirName);
end

% Loop through and save the maps
for ii = 1:length(fieldsToSave)
    outData = struct();
    switch p.Results.dataFileType
        case 'volumetric'
            fileName = fullfile(outDirName,[Subject '_' fieldsToSave{ii} '_map.nii.gz']);
            outData.vol = results.(fieldsToSave{ii});
            outData.nframes = 1;
            MRIwrite(outData, fileName);
        case 'cifti'
            fileName = fullfile(outDirName,[Subject '_' fieldsToSave{ii} '_map.dtseries.nii']);
            outData = templateImage;
            outData.cdata = single(results.(fieldsToSave{ii}));
            ciftisave(outData, fileName, workbenchPath)
        otherwise
            error('not a recognized dataFileType')
    end
end


end % Main function