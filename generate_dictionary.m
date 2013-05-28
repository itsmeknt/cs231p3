function [ ] = generate_dictionary(imageFileList, imageBaseDir, dataBaseDir, canSkip)

config;

GenerateSiftDescriptors( imageFileList,imageBaseDir,dataBaseDir,maxImageSize,gridSpacing,patchSize,canSkip);
CalculateDictionary(imageFileList,dataBaseDir,'_sift.mat',dictionarySize,numTextonImages,canSkip);
end

