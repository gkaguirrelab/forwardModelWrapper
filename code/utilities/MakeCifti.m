function MakeCifti(leftHemiMap, rightHemiMap, leftAtlasROI, rightAtlasROI, templateDtseries)

leftRaw = MRIread(leftHemiMap);
rightRaw = MRIread(rightHemiMap);

leftHemiData = leftRaw.vol(:);
rightHemiData = rightRaw.vol(:);
ciftiTemplate = ciftiopen(templateDtseries);
leftAtlas = gifti(leftAtlasROI);
rightAtlas = gifti(rightAtlasROI);

end 