function [pyramid_all class_label_all] = compute_features(imageFileList, imageBaseDir, dataBaseDir, canSkip)

config
addpath('spatial_pyramid_code');

GenerateSiftDescriptors(imageFileList,imageBaseDir,dataBaseDir,canSkip);
BuildHistograms(imageFileList,dataBaseDir,sprintf('_sift_ext_%d_%d_%d_%d_%d.mat', 0, 0, ext_param_3, 0, ext_param_5),canSkip);
[pyramid_all class_label_all] = CompilePyramid(imageFileList,dataBaseDir,sprintf('_texton_ind_%d_%d_ext_%d_%d_%d_%d_%d.mat',dictionarySize,numTextonImages,ext_param_1, ext_param_2, ext_param_3, 0, ext_param_5),canSkip);

end

