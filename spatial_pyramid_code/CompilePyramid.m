function [ pyramid_all class_label_all ] = CompilePyramid( imageFileList, dataBaseDir, textonSuffix, canSkip )
%function [ pyramid_all ] = CompilePyramid( imageFileList, dataBaseDir, textonSuffix, dictionarySize, pyramidLevels, canSkip )
%
% Generate the pyramid from the texton lablels
%
% For each image the texton labels are loaded. Then the histograms are
% calculated for the finest level. The rest of the pyramid levels are
% generated by combining the histograms of the higher level.
%
% imageFileList: cell of file paths
% dataBaseDir: the base directory for the data files that are generated
%  by the algorithm. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image file
% textonSuffix: this is the suffix appended to the image file name to
%  denote the data file that contains the textons indices and coordinates. 
%  Its default value is '_texton_ind_%d.mat' where %d is the dictionary
%  size.
% dictionarySize: size of descriptor dictionary (200 has been found to be
%  a good size)
% pyramidLevels: number of levels of the pyramid to build
% canSkip: if true the calculation will be skipped if the appropriate data 
%  file is found in dataBaseDir. This is very useful if you just want to
%  update some of the data or if you've added new images.

config;
% duplicate variables because parfor complains otherwise
copy_ext_param_1 = ext_param_1;
copy_ext_param_2 = ext_param_2;
copy_ext_param_3 = ext_param_3;
copy_ext_param_4 = ext_param_4;
copy_ext_param_5 = ext_param_5;
copy_dictionarySize = dictionarySize;
copy_numTextonImages = numTextonImages;
copy_pyramidLevels = pyramidLevels;
copy_poolType = poolType;
copy_poolNormalization = poolNormalization;
copy_use_pyramid_level_weights = use_pyramid_level_weights;
copy_num_image_batch_size = num_image_batch_size;

fprintf('Building Spatial Pyramid\n\n');

binsHigh = 2^(pyramidLevels-1);

pyramid_all = [];
class_label_all = zeros(size(imageFileList, 1),1);


%% Check cache
outFName = fullfile(dataBaseDir, sprintf('pyramids_all_%d_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, copy_pyramidLevels, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
if (canSkip && size(dir(outFName), 1) ~= 0)
    fprintf('Loading full pyramid cache...');
    load(outFName, 'pyramid_all', 'class_label_all');
    return;
end


num_batches = ceil(size(imageFileList,1)/num_image_batch_size);
for batch_idx = 1:num_batches
    entries_per_batch = min(copy_num_image_batch_size, size(imageFileList,1)-copy_num_image_batch_size*(batch_idx-1));
    if (size(imageFileList,1) < copy_num_image_batch_size)
        entries_per_batch = size(imageFileList,1);
    end
    pyramid_batch = cell(entries_per_batch,1);
    class_label_batch = cell(entries_per_batch,1);
    parfor entry_idx = 1:entries_per_batch
        %% load image
        imageFName = imageFileList{entry_idx+copy_num_image_batch_size*(batch_idx-1)};
        [dirN base] = fileparts(imageFName);
        baseFName = fullfile(dirN, base);
        
        outFName = fullfile(dataBaseDir, sprintf('%s_pyramid_%d_%d_%d_ext_%d_%d_%d_%d_%d.mat', baseFName, copy_dictionarySize, copy_numTextonImages, copy_pyramidLevels, copy_ext_param_1, copy_ext_param_2, copy_ext_param_3, copy_ext_param_4, copy_ext_param_5));
        
        if(size(dir(outFName),1)~=0 && canSkip)
            fprintf('Skipping CompilePyramid %s\n', imageFName);
            allVar = load(outFName, 'pyramid', 'class_label');
            pyramid = allVar.pyramid;
            class_label = allVar.class_label;
            
            pyramid_batch{entry_idx} = pyramid;
            class_label_batch{entry_idx} = class_label;
            
            continue;
        end
        
        %% load texton indices
        in_fname = fullfile(dataBaseDir, sprintf('%s%s', baseFName, textonSuffix));
        allVar = load(in_fname, 'texton_ind');
        texton_ind = allVar.texton_ind;
        
        %% get width and height of input image
        wid = texton_ind.wid;
        hgt = texton_ind.hgt;
        
        fprintf('%d/%d Building spatial pyramid for %s: wid %d, hgt %d\n', ...
            (entry_idx+copy_num_image_batch_size*(batch_idx-1)), size(imageFileList,1), imageFName, wid, hgt);
        
        %% compute histogram at the finest level
        pyramid_cell = cell(copy_pyramidLevels,1);
        pyramid_cell{1} = zeros(binsHigh, binsHigh, copy_dictionarySize);
        
        for i=1:binsHigh
            for j=1:binsHigh
                
                % find the coordinates of the current bin
                x_lo = floor(wid/binsHigh * (i-1));
                x_hi = floor(wid/binsHigh * i);
                y_lo = floor(hgt/binsHigh * (j-1));
                y_hi = floor(hgt/binsHigh * j);
                
                patch_codewords_transpose = texton_ind.data( (texton_ind.x > x_lo) & (texton_ind.x <= x_hi) & ...
                    (texton_ind.y > y_lo) & (texton_ind.y <= y_hi), :)';        % M x num_patches dim
                if (strcmp(copy_poolType, 'sum'))
                    pyramid_cell{1}(i,j,:) = sum(patch_codewords_transpose,2);
                elseif (strcmp(copy_poolType, 'max'))
                    pyramid_cell{1}(i,j,:) = max(patch_codewords_transpose,[],2);
                else
                    error(['poolType "' poolType '" not supported! Currently only support "sum" and "max"']);
                end
            end
        end
        
        %% compute histograms at the coarser levels
        num_bins = binsHigh/2;
        for l = 2:copy_pyramidLevels
            pyramid_cell{l} = zeros(num_bins, num_bins, copy_dictionarySize);
            for i=1:num_bins
                for j=1:num_bins
                    if (strcmp(copy_poolType, 'sum'))
                        pyramid_cell{l}(i,j,:) = pyramid_cell{l-1}(2*i-1,2*j-1,:) + pyramid_cell{l-1}(2*i,2*j-1,:) + pyramid_cell{l-1}(2*i-1,2*j,:) + pyramid_cell{l-1}(2*i,2*j,:);
                    elseif (strcmp(copy_poolType, 'max'))
                        pyramid_cell{l}(i,j,:) = max(max(pyramid_cell{l-1}(2*i-1,2*j-1,:), pyramid_cell{l-1}(2*i,2*j-1,:)), max(pyramid_cell{l-1}(2*i-1,2*j,:), pyramid_cell{l-1}(2*i,2*j,:)));
                    else
                        error(['poolType "' poolType '" not supported! Currently only support "sum" and "max"']);
                    end
                end
            end
            num_bins = num_bins/2;
        end
        
        % normalize
        if (strcmp(copy_poolNormalization,'sum'))
            total_sum = sum(sum(texton_ind.data));
            if total_sum == 0
                total_sum = 1;
            end
        end
        for l = 1:copy_pyramidLevels
            if (strcmp(copy_poolNormalization,'sum'))
                pyramid_cell{l} = pyramid_cell{l}/total_sum;
            elseif (strcmp(copy_poolNormalization,'L2'))
                denominator = sqrt(sum(pyramid_cell{l}.^2,3));
                denominator(denominator==0)=1;
                pyramid_cell{l} = bsxfun(@rdivide, pyramid_cell{l}, denominator);
            else
                error(['poolNormalization "' copy_poolNormalization '" not supported! Currently only support "sum" and "L2"']);
            end
        end
        
        %% stack all the histograms with appropriate weights
        pyramid = [];
        if (copy_use_pyramid_level_weights)
            for l = 1:copy_pyramidLevels-1
                pyramid = [pyramid pyramid_cell{l}(:)' .* 2^(-l)];
            end
            pyramid = [pyramid pyramid_cell{copy_pyramidLevels}(:)' .* 2^(1-copy_pyramidLevels)];
        else
            for l = 1:copy_pyramidLevels-1
                pyramid = [pyramid pyramid_cell{l}(:)'];
            end
            pyramid = [pyramid pyramid_cell{copy_pyramidLevels}(:)'];
        end
        
        pyramid_batch{entry_idx} = pyramid;
            
        class_label = get_class_label(base);
        class_label_batch{entry_idx} = class_label;
    end
    
    for entry_idx = 1:entries_per_batch
        imageFName = imageFileList{entry_idx+copy_num_image_batch_size*(batch_idx-1)};
        [dirN base] = fileparts(imageFName);
        baseFName = fullfile(dirN, base);
        
        outFName = fullfile(dataBaseDir, sprintf('%s_pyramid_%d_%d_%d_ext_%d_%d_%d_%d_%d.mat', baseFName, copy_dictionarySize, copy_numTextonImages, copy_pyramidLevels, copy_ext_param_1, copy_ext_param_2, copy_ext_param_3, copy_ext_param_4, copy_ext_param_5));
        
        % save pyramid
        pyramid = pyramid_batch{entry_idx};
        class_label = class_label_batch{entry_idx};
        
        if (isempty(pyramid_all))
            pyramid_all = zeros(size(imageFileList,1), size(pyramid,2));
        end
        
        pyramid_all(entry_idx+copy_num_image_batch_size*(batch_idx-1),:) = pyramid;
        class_label_all(entry_idx+copy_num_image_batch_size*(batch_idx-1)) = class_label;
        
        if(size(dir(outFName),1)~=0 && canSkip)
            fprintf('Skipping CompilePyramid %s\n', imageFName);
            continue;
        end
        
        sp_make_dir(outFName);
        save(outFName, 'pyramid', 'class_label');
    end
end

outFName = fullfile(dataBaseDir, sprintf('pyramids_all_%d_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, pyramidLevels, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
save(outFName, 'pyramid_all', 'class_label_all');


end
