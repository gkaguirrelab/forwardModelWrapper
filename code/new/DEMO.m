% Path variables
workbench_path = '/home/ozzy/workbench/bin_linux64/wb_command';
inputDir = '/home/ozzy/Desktop/test/TOME_3043_ICAFIX_multi_tfMRI_FLASH_AP_run1_tfMRI_FLASH_PA_run2_hcpicafix.zip';
stimFileName = '/home/ozzy/Desktop/test_ic/pRFStimulus.mat';
tempWorkingDir = '/home/ozzy/Desktop/test/';

% Analyze PRF variables
tr = '0.8';

% Variables for post processing
dataFileType = 'cifti';
pixelToDegree = '5.18';

% Output Path
outpath = '/home/ozzy/Desktop/test/results_folder/';

[data, stimulus, dataFileType, vxs, templateImage] = AnalzePRFPreprocess(workbench_path, inputDir, stimFileName, tempWorkingDir, dataFileType);
results = WrapperAnalyzePRF(stimulus, data, tr);
AnalzePRFPostprocess(results, templateImage, dataFileType, outpath)

