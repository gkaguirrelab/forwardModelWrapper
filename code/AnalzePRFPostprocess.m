function AnalzePRFPostprocess(results, templateImageDims, outpath, workbenchPath, varargin)
% Produce maps from the analyzePRF results
%
% Syntax:
%  AnalzePRFPostprocess(results, templateImageDims, outpath, workbenchPath)
%
% Description:
%   This routine produces maps from the results structure returned by
%   analyzePRF.
%
% Inputs:
%   results               - Structure. Contains the results produced by
%                           the analyzePRF routine. 
%   templateImageDims     - Vector. These are the dimensions of the source
%                           acquisition data.
%   outpath               - String. Path to the directory in which ouput
%                           files are to be saved
%   workbenchPath         - String. path to workbench_command
%
% Optional key/value pairs:
%   dataFileType          - String. Select whether the data is volumetric
%                           or surface (CIFTI). Options: volumetric/cifti
%   pixelToDegree         - String. Fill this in
%
% Outputs:
%   None. Saves files.
%


%% Parse inputs
p = inputParser; p.KeepUnmatched = true;

% Required
p.addRequired('results', @isstruct);
p.addRequired('templateImageDims', @isnumeric);
p.addRequired('outpath', @isstr);
p.addRequired('workbenchPath', @isstr);

% Optional
p.addParameter('dataFileType', 'cifti', @isstr)
p.addParameter('pixelToDegree', 'Na', @isstr)

% Parse
p.parse(results, templateImageDims, outpath, workbenchPath, varargin{:})



%% Process the results

% Copy the results variable over to a modified results
modifiedResults = results;

% Reshape the results to have the dimensions defined by the
% templateImageDims
fieldsToAdjust = {'ang','ecc','expt','rfsize','R2','gain'};
for ii = 1:length(fieldsToAdjust)
    modifiedResults.(fieldsToAdjust{ii}) = ...
        reshape(results.(fieldsToAdjust{ii}),[templateImageDims(1:end-1) 1]);
end

% We find that the eccentricity map contains values of exactly zero at
% points where model fitting failed. We set these points to nan in all
% result maps.
zeroIdx = modifiedResults.ecc==0;
for ii = 1:length(fieldsToAdjust)
    modifiedResults.(fieldsToAdjust{ii})(zeroIdx) = nan;
end

% If supplied, use the pixelToDegree value to convert the result data to
% units of visual angle in degrees
if ~strcmp(p.Results.pixelToDegree,'Na')
    modifiedResults.ecc = modifiedResults.ecc ./ str2double(p.Results.pixelToDegree);
    modifiedResults.rfsize = modifiedResults.rfsize ./ str2double(p.Results.pixelToDegree);
end

% We sometimes find unnaturally large eccentricity values (>90 degrees of
% visual angle). We presume that these are the result of model fitting
% failures. Remove these.
if strcmp(p.Results.pixelToDegree,'Na')
    bigAngleIdx = modifiedResults.ecc > 90;
else
    bigAngleIdx = [];
end
for ii = 1:length(fieldsToAdjust)
    modifiedResults.(fieldsToAdjust{ii})(bigAngleIdx) = nan;
end

% Convert from polar angle to cartesian coordinates. We save out maps in
% cartesian coordinates as these are better behaved in subsequent averaging
% and interpolation steps.
modifiedResults.cartX = modifiedResults.ecc .* cosd(modifiedResults.ang);
modifiedResults.cartY = modifiedResults.ecc .* sind(modifiedResults.ang);

% Convert R2 from percent to proportion
modifiedResults.R2 = modifiedResults.R2 ./ 100;

% Negative R2 values can result in areas of extremely poor model fit. We
% set these to zero keep the R2 values in the domain of 0-1.
modifiedResults.R2(modifiedResults.R2<0) = 0;


%% Save output

% Save raw retinotopy results
save(strcat(outpath,'raw_retinotopy_results.mat'),'results')

% Save modified retinotopy results
save(strcat(outpath,'modified_retinotopy_results.mat'),'modifiedResults')

% Save retintopy maps
fieldsToSave = {'ang','ecc','expt','rfsize','R2','gain','cartX','cartY'};

for ii = 1:length(fieldsToSave)
    outData = struct();
    switch p.Results.dataFileType
        case 'volumetric'
            fileName = fullfile(outpath,[fieldsToSave{ii} '_map.nii.gz']);
            outData.vol = modifiedResults.(fieldsToSave{ii});
            outData.nframes = 1;
            MRIwrite(outData, fileName);
        case 'cifti'
            fileName = fullfile(outpath,[fieldsToSave{ii} '_map.dtseries.nii']);
            outData.cdata = modifiedResults.(fieldsToSave{ii});
            ciftisave(outData, fileName, workbenchPath)
        otherwise
            error('not a recognized dataFileType')
    end
end


end % Main function