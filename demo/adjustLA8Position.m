% DEMO_LDOGglm
%
% This routine downloads LDOG struct and func data from flywheel and then
% submits the files for analysis


% Clear out variables from the workspace, as we will be passing these
% within the workspace to forwardModel
clear



%% Variable declaration
projectName = 'forwardModelWrapper';
scratchSaveDir = getpref(projectName,'flywheelScratchDir');
subjectName = 'LA8';

% Create the functional tmp save dir if it does not exist
saveDir = fullfile(scratchSaveDir,'v0','input','funcZip');
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Create a flywheel object and get the acquisition list
fw = flywheel.Flywheel(getpref(projectName,'flywheelAPIKey'));
sessionID = '65b2a4010b320e38e1c95f5f';
acquisitionList = fw.getSessionAcquisitions(sessionID);

% Download the acquisitions; skip over the Phoenix file
acqIdx = [7:21,23:25];
nAcq = length(acqIdx);
for ii = 1:nAcq
    acquisitionId{ii} = acquisitionList{acqIdx(ii)}.id;
    fileID = acquisitionList{acqIdx(ii)}.files{3}.fileId;
    fileName{ii} = acquisitionList{acqIdx(ii)}.files{3}.name;
    savePath = fullfile(saveDir,fileName{ii});
    % fw.downloadFileFromAcquisition(acquisitionId{ii},fileName{ii},savePath);
end

% Extract the average volume from each acquisition
for ii = 1:nAcq
    loadPath = fullfile(saveDir,fileName{ii});
    temp = MRIread(loadPath);
    avgVol{ii} = squeeze(mean(temp.vol,4));
end

% I examined the images and by hand determined the x and y shift needed to
% bring each acquisition back into alignment with the first acquisition
% obtained in the same phase encode direction
dirSets{1} = [1 4 5 7 11 13 16 17 18];
dirSets{2} = [2 3 6 8 9 10 12 14 15];

% Define properties for the registration
metric = registration.metric.MeanSquares;
optimizer = registration.optimizer.RegularStepGradientDescent;

for ss = 1:length(dirSets)
    thisSet = dirSets{ss};
    fixed = avgVol{thisSet(1)}(15:55,:,:);
    for aa = 2:length(thisSet)

        % Some items for the registration
        moving = avgVol{thisSet(aa)}(15:55,:,:);
        tform = imregtform(moving,fixed,'rigid',optimizer,metric);
        sameAsInput = affineOutputView(size(avgVol{thisSet(aa)}),tform,"BoundsStyle","SameAsInput");

        % Load the entire acquisition and correct each TR
        loadPath = fullfile(saveDir,fileName{thisSet(aa)});
        temp = MRIread(loadPath);
        newVol = int32(zeros(size(temp.vol)));
        for ii = 1:temp.nframes
            frame = squeeze(temp.vol(:,:,:,ii));
            frame_reg = imwarp(frame,tform,"OutputView",sameAsInput);
            newVol(:,:,:,ii) = int32(round(frame_reg));
        end

        % Save the corrected acquisition
        hdr = temp.niftihdr;
        hdr.vol = permute(newVol,[2 1 3 4]);
        newName = strsplit(fileName{thisSet(aa)},'.');
        newName = [newName{1} '_reg.nii.gz'];
        savePath = fullfile(saveDir,newName);
        save_nifti(hdr,savePath);

        clear temp
        clear hdr

        % Upload the corrected acquisition to flywheel
        fw.uploadFileToAcquisition(acquisitionId{thisSet(aa)},savePath);

    end

end



%% Local functions



function plotSlice(vol,xShift,yShift)
im = fshift(fshift(squeeze(vol(:,32,:))',xShift)',yShift);
imagesc(im)
colormap(gray)
axis equal
%xlim([0,30])
box off
axis off
%hold on
end