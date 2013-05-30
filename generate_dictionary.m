function [ ] = generate_dictionary(trainingFileList, trainingBaseDir, trainingCacheDir, testCacheDir, canSkip)

config;

dictFileName = sprintf('dictionary_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5);
dictTrainingCache = fullfile(trainingCacheDir, dictFileName);
dictTestCache = fullfile(testCacheDir, dictFileName);

if (~canSkip || size(dir(dictTrainingCache),1)==0 || size(dir(dictTestCache),1)==0)
    GenerateSiftDescriptors(trainingFileList,trainingBaseDir,trainingCacheDir,maxImageSize,gridSpacing,patchSize,canSkip, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5);
    CalculateDictionary(trainingFileList,trainingCacheDir,sprintf('_sift_ext_%d_%d_%d_%d_%d.mat',ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5),dictionarySize,numTextonImages,canSkip, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5);
end

% copy dictionary file from training cache to test cache. We use same
% dictionary in both train and test
if (size(dir(testCacheDir),1)==0)
    mkdir(testCacheDir);
end
copyfile(dictTrainingCache, dictTestCache);
end

