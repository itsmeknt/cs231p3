function [] = GenerateSiftDescriptors( imageFileList, imageBaseDir, dataBaseDir, canSkip )
%function [] = GenerateSiftDescriptors( imageFileList, imageBaseDir, dataBaseDir, maxImageSize, gridSpacing, patchSize, canSkip )
%
%Generate the dense grid of sift descriptors for each
% image
%
% imageFileList: cell of file paths
% imageBaseDir: the base directory for the image files
% dataBaseDir: the base directory for the data files that are generated
%  by the algorithm. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image files
% maxImageSize: the max image size. If the image is larger it will be
%  resampeled.
% gridSpacing: the spacing for the grid to be used when generating the
%  sift descriptors
% patchSize: the patch size used for generating the sift descriptor
% canSkip: if true the calculation will be skipped if the appropriate data 
%  file is found in dataBaseDir. This is very useful if you just want to
%  update some of the data or if you've added new images.

config;
% duplicate variables because parfor complains otherwise
copy_ext_param_3 = ext_param_3;
copy_ext_param_4 = ext_param_4;
copy_ext_param_5 = ext_param_5;
copy_maxImageSize = maxImageSize;
copy_num_image_batch_size = num_image_batch_size;
copy_patchSize = patchSize;
copy_gridSpacing = gridSpacing;
fprintf('Building Sift Descriptors\n\n');

num_batches = ceil(size(imageFileList,1)/num_image_batch_size);
for batch_idx = 1:num_batches
    entries_per_batch = min(copy_num_image_batch_size, size(imageFileList,1)-copy_num_image_batch_size*(batch_idx-1));
    if (size(imageFileList,1) < copy_num_image_batch_size)
        entries_per_batch = size(imageFileList,1);
    end
    feature_cells = cell(entries_per_batch); % use min so it won't fail if array size dont match (it should)
    parfor entry_idx = 1:entries_per_batch
        %% load image
        imageFName = imageFileList{entry_idx+copy_num_image_batch_size*(batch_idx-1)};
        [dirN base] = fileparts(imageFName);
        baseFName = [dirN filesep base];
        outFName = fullfile(dataBaseDir, sprintf('%s_sift_ext_%d_%d_%d_%d_%d.mat', baseFName, 0, 0, copy_ext_param_3, 0, copy_ext_param_5));
        imageFName = fullfile(imageBaseDir, imageFName);
        
        if(size(dir(outFName),1)~=0 && canSkip)
            fprintf('Skipping GenerateSiftDescriptors %s\n', imageFName);
            continue;
        end
        
        I = sp_load_image(imageFName);
        
        [hgt wid] = size(I);
        if min(hgt,wid) > copy_maxImageSize
            I = imresize(I, copy_maxImageSize/min(hgt,wid), 'bicubic');
            fprintf('%d/%d Generating SIFT descriptors for %s: original size %d x %d, resizing to %d x %d\n', ...
                (entry_idx+copy_num_image_batch_size*(batch_idx-1)), size(imageFileList,1), imageFName, wid, hgt, size(I,2), size(I,1));
            [hgt wid] = size(I);
        end
        
        %% make grid (coordinates of upper left patch corners)
        features = [];
        for d = 1:min(length(copy_patchSize),length(copy_gridSpacing)) % use min so it won't fail if array size dont match (it should)
            curr_patchSize = copy_patchSize(d);
            curr_gridSpacing = copy_gridSpacing(d);
            
            remX = mod(wid-curr_patchSize,curr_gridSpacing);
            offsetX = floor(remX/2)+1;
            remY = mod(hgt-curr_patchSize,curr_gridSpacing);
            offsetY = floor(remY/2)+1;
            
            [gridX,gridY] = meshgrid(offsetX:curr_gridSpacing:wid-curr_patchSize+1, offsetY:curr_gridSpacing:hgt-curr_patchSize+1);
            
            fprintf('%d/%d Processing %s: wid %d, hgt %d, grid size: %d x %d, %d patches\n', ...
                (entry_idx+copy_num_image_batch_size*(batch_idx-1)), size(imageFileList,1), imageFName, wid, hgt, size(gridX,2), size(gridX,1), numel(gridX));
            
            %% find SIFT descriptors
            siftArr = sp_find_sift_grid(I, gridX, gridY, curr_patchSize, 0.8);
            siftArr = sp_normalize_sift(siftArr);
            
            feature = [];
            feature.data = siftArr;
            feature.x = gridX(:) + curr_patchSize/2 - 0.5;
            feature.y = gridY(:) + curr_patchSize/2 - 0.5;
            feature.wid = wid;
            feature.hgt = hgt;
            
            features = [features; feature];
        end
        feature_cells{entry_idx} = features;
        
    end % for
    
    
    for entry_idx = 1:entries_per_batch
        
        %% load image
        imageFName = imageFileList{entry_idx+copy_num_image_batch_size*(batch_idx-1)};
        [dirN base] = fileparts(imageFName);
        baseFName = [dirN filesep base];
        outFName = fullfile(dataBaseDir, sprintf('%s_sift_ext_%d_%d_%d_%d_%d.mat', baseFName, 0, 0, copy_ext_param_3, 0, copy_ext_param_5));
        imageFName = fullfile(imageBaseDir, imageFName);
        
        if(size(dir(outFName),1)~=0 && canSkip)
            fprintf('Skipping GenerateSiftDescriptors %s\n', imageFName);
            continue;
        end
        
        features = feature_cells{entry_idx};
        sp_make_dir(outFName);
        save(outFName, 'features');
    end
end

end % function
