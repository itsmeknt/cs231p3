function [pyramid_all class_label_all] = compute_features(imageFileList, imageBaseDir, dataBaseDir, canSkip)

config;

GenerateSiftDescriptors(imageFileList,imageBaseDir,dataBaseDir,maxImageSize,gridSpacing,patchSize,canSkip);
BuildHistograms(imageFileList,dataBaseDir,'_sift.mat',dictionarySize,canSkip);
[pyramid_all class_label_all] = CompilePyramid(imageFileList,dataBaseDir,sprintf('_texton_ind_%d.mat',dictionarySize),dictionarySize,pyramidLevels,canSkip);

end

