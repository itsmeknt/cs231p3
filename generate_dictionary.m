function [ ] = generate_dictionary(trainingFileList, trainingBaseDir, trainingCacheDir, testCacheDir, canSkip)

config;

GenerateSiftDescriptors( trainingFileList,trainingBaseDir,trainingCacheDir,maxImageSize,gridSpacing,patchSize,canSkip);
CalculateDictionary(trainingFileList,trainingCacheDir,'_sift.mat',dictionarySize,numTextonImages,canSkip);

% copy dictionary file from training cache to test cache. We use same
% dictionary in both train and test
dictFileName = sprintf('dictionary_%d.mat', dictionarySize);
dictTrainingCache = fullfile(trainingCacheDir, dictFileName);
dictTestCache = fullfile(testCacheDir, dictFileName);
copyfile(dictTrainingCache, dictTestCache);
end

