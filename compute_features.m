function [pyramid_all class_label_all] = compute_features(imageFileList, imageBaseDir, dataBaseDir, canSkip)

config

GenerateSiftDescriptors(imageFileList,imageBaseDir,dataBaseDir,maxImageSize,gridSpacing,patchSize,canSkip, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5);
BuildHistograms(imageFileList,dataBaseDir,sprintf('_sift_ext_%d_%d_%d_%d_%d.mat',ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5),dictionarySize,numTextonImages,canSkip,ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5);
[pyramid_all class_label_all] = CompilePyramid(imageFileList,dataBaseDir,sprintf('_texton_ind_%d_%d_ext_%d_%d_%d_%d_%d.mat',dictionarySize,numTextonImages,ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5),dictionarySize,numTextonImages,pyramidLevels,canSkip,ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5);

end

