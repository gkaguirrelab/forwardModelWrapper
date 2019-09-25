function AnalzePRFPostprocess(results, templateImage, dataFileType, outpath, varargin)

p = inputParser; p.KeepUnmatched = true;

% Required  
p.addRequired('stimulus', @isstruct);
p.addRequired('templateImage', @isstr);
p.addRequired('dataFileType', @isstr);
p.addRequired('outpath', @isstr);

% Optional
p.addParameter('pixelToDegree',"Na", @isstr)

% Save raw retinotopy results
save(strcat(outpath,"raw_retinotopy_results.mat"),'results')

%% Load the raw image again to modify and make maps

if dataFileType == "volumetric"
    rawData = MRIread(templateImage);
    %MAKE 3D
    getsize = size(rawData.vol); %Get the size of the original scan 
    % Results converted 2D -> 3D
    results.ecc = reshape(results.ecc,[getsize(1) getsize(2) getsize(3) 1]);
    results.ang = reshape(results.ang,[getsize(1) getsize(2) getsize(3) 1]);
    results.expt = reshape(results.expt,[getsize(1) getsize(2) getsize(3) 1]);
    results.rfsize = reshape(results.rfsize,[getsize(1) getsize(2) getsize(3) 1]);
    results.R2 = reshape(results.R2,[getsize(1) getsize(2) getsize(3) 1]);
    results.gain = reshape(results.gain,[getsize(1) getsize(2) getsize(3) 1]);
else 
    rawData = ciftiopen(templateImage, workbench_path);
end

% Whenever there is a zero value in ecccentricity map set angle to NaN.
% Changes the original output values
zero_indices_ecc = find(results.ecc == 0);
for zero_vals = zero_indices_ecc'
    results.ang(zero_vals) = NaN;
end

% Replace ecc values with NaN if they are larger than 90 pixels
results.ecc(results.ecc > 90) = NaN;

%%%Pixel to Degrees conversion. Changes the original output values
if p.Results.pixelToDegree ~= "Na"
    results.ecc = results.ecc ./ str2double(p.Results.pixelToDegree);
    results.rfsize = results.rfsize ./ str2double(p.Results.pixelToDegree);
end

% Create cartesian maps
vector_length = length(results.ecc);
x_map = [];
y_map = [];
for ii = 1:vector_length
    temporary_ecc = results.ecc(ii);
    temporary_ang = results.ang(ii); 
    x_map(ii) = temporary_ecc * cosd(temporary_ang);
    y_map(ii) = temporary_ecc * sind(temporary_ang);
end
x_map = x_map';
y_map = y_map';

%~~~~~~~~COMMENTED OUT. WE DO THIS IN THE PYTHON SCRIPT NOW~~~~~~~~~~~~~ 
%%% The output of this analysis will be used in Bayesian Analysis of  
%%% Retinotopic Maps (Benson & Winawer,2018). Therefore the polar angle 
%%% should be converted in a way that -90 and 90 degrees will correspond 
%%% to left and right horizontal meridians and upper and lower vertical 
%%% meridians will be 0 and ±180 degrees respectively.
%if p.Results.convertAngleForBayes ~= "0" 
%    %angle_converted = wrapTo180(wrapTo360(abs(results.ang-360)+90));
%    angle_converted = mod(abs(results.ang-360)+90,360);
%    idx = (angle_converted < -180) | (180 < angle_converted);
%    angle_converted(idx) = mod(angle_converted(idx) + 180,360) - 180; 
%end

%%% Divide R2 by 100 and set negative values to zero and values larger than
%%% 1 to 1 - Changes the original output values.
results.R2 = results.R2 ./ 100;
results.R2(results.R2 < 0) = 0;

% Save processed retinotopy results
save(strcat(outpath,"processed_retinotopy_results.mat"),'results')

%SAVE NIFTI or CIFTI results
if dataFileType == "volumetric"
    rawData.nframes = 1; %Set the 4th dimension 1
    rawData.vol = results.ecc;
    MRIwrite(rawData, strcat(outpath,'eccentricity_map.nii.gz'))
    rawData.vol = results.ang;
    MRIwrite(rawData, strcat(outpath,'angle_map.nii.gz'))
    rawData.vol = results.expt;
    MRIwrite(rawData, strcat(outpath,'exponent_map.nii.gz'))
    rawData.vol = results.rfsize;
    MRIwrite(rawData, strcat(outpath,'rfsize_map.nii.gz'))
    rawData.vol = results.R2;
    MRIwrite(rawData, strcat(outpath,'R2_map.nii.gz'))
    rawData.vol = results.gain;
    MRIwrite(rawData, strcat(outpath,'gain_map.nii.gz'))
    rawData.vol = x_map;
    MRIwrite(rawData, strcat(outpath,'x_map.nii.gz'))
    rawData.vol = y_map;
    MRIwrite(rawData, strcat(outpath,'y_map.nii.gz'))
    if p.Results.thresholdData ~= "Na"
        rawData.nframes = 1; %Set the 4th dimension 1
        rawData.vol = results_thresh.ecc;
        MRIwrite(rawData, strcat(outpath,'thresh_eccentricity_map.nii.gz'))
        rawData.vol = results_thresh.ang;
        MRIwrite(rawData, strcat(outpath,'thresh_angle_map.nii.gz'))
        rawData.vol = results_thresh.expt;
        MRIwrite(rawData, strcat(outpath,'thresh_exponent_map.nii.gz'))
        rawData.vol = results_thresh.rfsize;
        MRIwrite(rawData, strcat(outpath,'thresh_rfsize_map.nii.gz'))
        rawData.vol = results_thresh.R2;
        MRIwrite(rawData, strcat(outpath,'thresh_R2_map.nii.gz'))
        rawData.vol = results_thresh.gain;
        MRIwrite(rawData, strcat(outpath,'thresh_gain_map.nii.gz'))
    end
    
elseif dataFileType == "cifti"
    rawData.cdata = results.ecc;
    ciftisave(rawData, strcat(outpath,'eccentricity_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.ang;
    ciftisave(rawData, strcat(outpath,'angle_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.expt;
    ciftisave(rawData, strcat(outpath,'exponent_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.rfsize;
    ciftisave(rawData, strcat(outpath,'rfsize_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.R2;
    ciftisave(rawData, strcat(outpath,'R2_map.dtseries.nii'), workbench_path)
    rawData.cdata = results.gain;
    ciftisave(rawData, strcat(outpath,'gain_map.dtseries.nii'), workbench_path) 
    rawData.cdata = x_map;
    ciftisave(rawData, strcat(outpath,'x_map.dtseries.nii'), workbench_path)
    rawData.cdata = y_map;
    ciftisave(rawData, strcat(outpath,'y_map.dtseries.nii'), workbench_path) 
%     if p.Results.convertAngleForBayes ~= "0"
%         rawData.cdata = angle_converted;
%         ciftisave(rawData, strcat(outpath,'converted_angle_map.dtseries.nii'), workbench_path)     
%     end    
end
end