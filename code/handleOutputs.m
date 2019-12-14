function mapOutDirName = handleOutputs(results, templateImage, outPath, Subject, workbenchPath, varargin)
% Produce maps from the forwardModel results
%
% Syntax:
%  outDirName = handleOutputs(results, templateImage, outPath, Subject, workbenchPath)
%
% Description:
%   This routine saves results, plots, and maps returned by forwardModel.
%
% Inputs:
%   results               - Structure. Contains the results produced by
%                           the forwardModel routine.
%   templateImage         - Type dependent upon the nature of the input
%                           data
%   outPath               - String. Path to the directory in which ouput
%                           files are to be saved
%   Subject               - String. The subject ID or name.
%   workbenchPath         - String. path to workbench_command
%
% Optional key/value pairs:
%   dataFileType          - String. Select whether the data is volumetric
%                           or surface (CIFTI). Options: volumetric/cifti
%
% Outputs:
%   mapOutDirName         - String. Where the maps were saved.


%% Parse inputs
p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('results', @isstruct);
p.addRequired('templateImage', @(x)(isobject(x) | isstruct(x) | isnumeric(x)));
p.addRequired('outPath', @isstr);
p.addRequired('Subject', @isstr);
p.addRequired('workbenchPath', @isstr);

% Optional
p.addParameter('dataFileType', 'cifti', @isstr)

% Parse
p.parse(results, templateImage, outPath, Subject, workbenchPath, varargin{:})



%% Save results mat file
save(fullfile(outPath,[Subject '_' results.model.class '_results.mat']),'results')


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


%% If we have maps, save them

if ~isfield(results.meta,'mapField')
    
    mapOutDirName = [];
    
else
    
    %% Reshape the parameters
    % For volumetric results, we need to reshape the data to have the
    % dimensions defined by the templateImage
    fieldsToSave = results.meta.mapField;
    if strcmp(p.Results.dataFileType,'volumetric')
        sizer = size(templateImage.vol);
        for ii = 1:length(fieldsToSave)
            results.(fieldsToSave{ii}) = ...
                reshape(results.(fieldsToSave{ii}),[sizer(1:end-1) 1]);
        end
    end
    
    %% Create parameter maps
    % Create a maps directory
    mapOutDirName = fullfile(outPath,[Subject '_maps_' p.Results.dataFileType]);
    if ~exist(mapOutDirName,'dir')
        mkdir(mapOutDirName);
    end
    
    % Loop through and save the maps
    for ii = 1:length(fieldsToSave)
        outData = struct();
        switch p.Results.dataFileType
            case 'volumetric'
                fileName = fullfile(mapOutDirName,[Subject '_' fieldsToSave{ii} '_map.nii.gz']);
                outData.vol = results.(fieldsToSave{ii});
                outData.nframes = 1;
                MRIwrite(outData, fileName);
            case 'cifti'
                fileName = fullfile(mapOutDirName,[Subject '_' fieldsToSave{ii} '_map.dtseries.nii']);
                outData = templateImage;
                outData.cdata = single(results.(fieldsToSave{ii}));
                ciftisave(outData, fileName, workbenchPath)
            otherwise
                error('not a recognized dataFileType')
        end
    end
    
end

end % Main function