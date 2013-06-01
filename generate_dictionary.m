function [ ] = generate_dictionary(trainingFileList, trainingBaseDir, trainingCacheDir, testCacheDir, canSkip)

config;
addpath('spatial_pyramid_code');

dictFileName = sprintf('dictionary_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, 0, ext_param_2, ext_param_3, ext_param_4, ext_param_5);
dictTrainingCache = fullfile(trainingCacheDir, dictFileName);
dictTestCache = fullfile(testCacheDir, dictFileName);

if (~canSkip || size(dir(dictTrainingCache),1)==0 || size(dir(dictTestCache),1)==0)
    GenerateSiftDescriptors(trainingFileList,trainingBaseDir,trainingCacheDir,canSkip);
    if (balance_dictionary_training)
        trainingFileByClass = cell(0,1);
        for i=1:size(trainingFileList,1)
            imageFName = trainingFileList{i};
            classIdx = get_class_label(imageFName);
            if (length(trainingFileByClass) < classIdx || isempty(trainingFileByClass{classIdx}))
                fileListByClass = cell(0);
                fileListByClass{1} = imageFName;
                trainingFileByClass{classIdx} = fileListByClass;
            else
                fileListByClass = trainingFileByClass{classIdx};
                fileListByClass{length(fileListByClass)+1} = imageFName;
                trainingFileByClass{classIdx} = fileListByClass;
            end
        end
        
        dictionary = [];
        for i=1:length(trainingFileByClass)
            dictionary = [dictionary; CalculateDictionary(trainingFileByClass{i},trainingCacheDir,sprintf('_sift_ext_%d_%d_%d_%d_%d.mat',0, 0, ext_param_3, ext_param_4, ext_param_5),ceil(dictionarySize/length(trainingFileByClass)),canSkip, 0)]; 
        end
        if (size(dictionary,1) > dictionarySize)
            dictionary = dictionary(1:dictionarySize,:);
        end
        outFName = fullfile(trainingCacheDir, sprintf('dictionary_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, 0, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
        fprintf('Saving texton dictionary\n');
        sp_make_dir(outFName);
        save(outFName, 'dictionary');
    else
        CalculateDictionary(trainingFileList,trainingCacheDir,sprintf('_sift_ext_%d_%d_%d_%d_%d.mat',0, 0, ext_param_3, ext_param_4, ext_param_5),dictionarySize,canSkip, 1);
    end
end

% copy dictionary file from training cache to test cache. We use same
% dictionary in both train and test
if (size(dir(testCacheDir),1)==0)
    mkdir(testCacheDir);
end
copyfile(dictTrainingCache, dictTestCache);
end

