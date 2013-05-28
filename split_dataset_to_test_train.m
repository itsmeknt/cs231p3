function [ ] = split_dataset_to_test_train(dataset_dir, dataset_type)
% dataset_dir should have the same folder structure as downloaded
% (e.g. dataset_dir/class/unlabeled_images for the dataset_dir 'scene_categories'
% or dataset_dir/class/test-and-train-dirs for the dataset_dir
% 'norm_ppmi_12class/norm_image/play_instrument')

config;

out_base_dir = get_dataset_base_dir(dataset_type);
if (isempty(dir(out_base_dir)))
    mkdir(out_base_dir);
end
[out_train_dir out_test_dir] = get_dataset_training_test_dirs(out_base_dir);
if (isempty(dir(out_train_dir)))
    mkdir(out_train_dir);
end
if (isempty(dir(out_test_dir)))
    mkdir(out_test_dir);
end

if (strcmp(dataset_type, 'scene'))
    % folder structure is base_dir/category/unlabeled_images
     classDirs = dir(dataset_dir);
     for i=1:length(classDirs)
         classDir = classDirs(i);
         if (strcmp(classDir.name, '.') || strcmp(classDir.name, '..'))
             continue;
         end
         imgFiles = dir(fullfile(dataset_dir, classDir.name, '*.jpg'));
         
         numImgFilesCopied = 0;
         randIdxs = randsample(length(imgFiles), length(imgFiles));
         for j=1:length(randIdxs)
             imgFile = imgFiles(randIdxs(j));
             if (strcmp(imgFile.name, '.') || strcmp(imgFile.name, '..'))
                continue;
             end
        
             imgFilePath = fullfile(dataset_dir, classDir.name, imgFile.name);
             
             imgFileName = ['scene_category_' classDir.name '_' imgFile.name];
             
             if (numImgFilesCopied < NUM_TRAINING_IMAGES_SCENE)
                outFilePath = fullfile(out_train_dir, imgFileName);
             else
                outFilePath = fullfile(out_test_dir, imgFileName);
             end
             
             copyfile(imgFilePath, outFilePath);
             numImgFilesCopied = numImgFilesCopied+1;
         end
     end     
elseif (strcmp(dataset_type, 'ppmi'))
    IMAGE_DIR_DEFAULT = 'norm_ppmi_12class/norm_image/play_instrument';
end

end

