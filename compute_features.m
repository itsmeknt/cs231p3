function [pyramid_all] = compute_features(imageFileList, dataBaseDir, canSkip)
config;

BuildHistograms(imageFileList,dataBaseDir,'_sift.mat',dictionarySize,canSkip);
pyramid_all = CompilePyramid(imageFileList,dataBaseDir,sprintf('_texton_ind_%d.mat',dictionarySize),dictionarySize,pyramidLevels,canSkip);

end

