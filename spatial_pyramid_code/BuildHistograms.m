function [ ] = BuildHistograms( imageFileList, dataBaseDir, featureSuffix, canSkip )
%
%find texton labels of patches and compute texton histograms of all images
%   
% For each image the set of sift descriptors is loaded and then each
%  descriptor is labeled with its texton label. Then the global histogram
%  is calculated for the image. If you wish to just use the Bag of Features
%  image descriptor you can stop at this step, H_all is the histogram or
%  Bag of Features descriptor for all input images.
%
% imageFileList: cell of file paths
% imageBaseDir: the base directory for the image files
% dataBaseDir: the base directory for the data files that are generated
%  by the algorithm. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image file
% featureSuffix: this is the suffix appended to the image file name to
%  denote the data file that contains the feature textons and coordinates. 
%  Its default value is '_sift.mat'.
% dictionarySize: size of descriptor dictionary (200 has been found to be
%  a good size)
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
copy_code_constraint = code_constraint;
if (strcmp(copy_code_constraint, 'LLC'))
    copy_NN_k = NN_k;
    copy_epsilon = epsilon;
end
copy_num_image_batch_size = num_image_batch_size;
fprintf('Building Histograms\n\n');


%% load texton dictionary (all texton centers)

inFName = fullfile(dataBaseDir, sprintf('dictionary_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, 0, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
allVar = load(inFName,'dictionary');
dictionary = allVar.dictionary;

fprintf('Loaded texton dictionary: %d textons\n', dictionarySize);

%% compute texton labels of patches and whole-image histograms
num_batches = ceil(size(imageFileList,1)/num_image_batch_size);
for batch_idx = 1:num_batches
    entries_per_batch = min(copy_num_image_batch_size, size(imageFileList,1)-copy_num_image_batch_size*(batch_idx-1));
    if (size(imageFileList,1) < copy_num_image_batch_size)
        entries_per_batch = size(imageFileList,1);
    end
    texton_ind_batch = cell(entries_per_batch,1);
    for entry_idx = 1:entries_per_batch
        imageFName = imageFileList{entry_idx+copy_num_image_batch_size*(batch_idx-1)};
        [dirN base] = fileparts(imageFName);
        baseFName = fullfile(dirN, base);
        
        outFName = fullfile(dataBaseDir, sprintf('%s_texton_ind_%d_%d_ext_%d_%d_%d_%d_%d.mat', baseFName, copy_dictionarySize, copy_numTextonImages, copy_ext_param_1, copy_ext_param_2, copy_ext_param_3, copy_ext_param_4, copy_ext_param_5));
        if(size(dir(outFName),1)~=0 && canSkip)
            fprintf('Skipping BuildHistogram %s\n', imageFName);
            continue;
        end
        
        %% load sift descriptors
        inFName = fullfile(dataBaseDir, sprintf('%s%s', baseFName, featureSuffix));
        allVar = load(inFName, 'features');
        features = allVar.features;
        ndata = size(features.data,1);
        fprintf('%d/%d Building histogram for %s, %d descriptors\n', (entry_idx+copy_num_image_batch_size*(batch_idx-1)), size(imageFileList,1), inFName, ndata);
        
        %% find texton indices and compute histogram
        texton_ind = [];
        texton_ind.data = zeros(ndata, copy_dictionarySize);         % num_patches x M dim
        texton_ind.x = features.x;
        texton_ind.y = features.y;
        texton_ind.wid = features.wid;
        texton_ind.hgt = features.hgt;
        %run in batches to keep the memory foot print small
        batchSize = 10000;
        if ndata <= batchSize
            if (strcmp(copy_code_constraint, 'VC'))
                dist_mat = sp_dist2(features.data, dictionary);
                [~, min_ind] = min(dist_mat, [], 2);
                row = (1:length(min_ind))';
                col = min_ind;
                texton_ind.data(sub2ind(size(texton_ind.data),row,col)) = 1;
            elseif (strcmp(copy_code_constraint, 'LLC'))
                B_knn_idxs = knnsearch(dictionary, features.data, 'K', copy_NN_k, 'NSMethod','exhaustive','Distance','euclidean');
                for i=1:ndata
                    c = solve_LLC_KNN(features.data(i,:), dictionary, B_knn_idxs(i,:), copy_epsilon);
                    texton_ind.data(i,:) = c;
                end
            else
                error(['code constraint "' copy_code_constraint '" not supported! Currently only support "VC" and "LLC"']);
            end
        else
            for j = 1:batchSize:ndata
                lo = j;
                hi = min(j+batchSize-1,ndata);
                if (strcmp(copy_code_constraint, 'VC'))
                    dist_mat = dist2(features.data(lo:hi,:), dictionary);
                    [~, min_ind] = min(dist_mat, [], 2);
                    row = (1:length(min_ind))';
                    col = min_ind;
                    texton_ind.data(sub2ind(size(texton_ind.data),row,col)) = 1;
                elseif (strcmp(copy_code_constraint, 'LLC'))
                    B_knn_idxs = knnsearch(dictionary, features.data(lo:hi,:), 'K', copy_NN_k, 'NSMethod','exhaustive','Distance','euclidean');
                    for i=lo:hi
                        c = solve_LLC_KNN(features.data(i,:), dictionary, B_knn_idxs(i,:), copy_epsilon);
                        texton_ind.data(i,:) = c;
                    end
                else
                    error(['code constraint "' copy_code_constraint '" not supported! Currently only support "VC" and "LLC"']);
                end
            end
        end
        
        texton_ind_batch{entry_idx} = texton_ind;
        % H = hist(texton_ind.data, 1:copy_dictionarySize);
        % H_all = [H_all; H];
    end
    
    for entry_idx = 1:entries_per_batch
        imageFName = imageFileList{entry_idx+copy_num_image_batch_size*(batch_idx-1)};
        [dirN base] = fileparts(imageFName);
        baseFName = fullfile(dirN, base);
        
        outFName = fullfile(dataBaseDir, sprintf('%s_texton_ind_%d_%d_ext_%d_%d_%d_%d_%d.mat', baseFName, copy_dictionarySize, copy_numTextonImages, copy_ext_param_1, copy_ext_param_2, copy_ext_param_3, copy_ext_param_4, copy_ext_param_5));
        if(size(dir(outFName),1)~=0 && canSkip)
            fprintf('Skipping BuildHistogram %s\n', imageFName);
            continue;
        end
        
        %% save texton indices and histograms
        texton_ind = texton_ind_batch{entry_idx};
        sp_make_dir(outFName);
        save(outFName, 'texton_ind');
    end
end


%% save histograms of all images in this directory in a single file
% outFName = fullfile(dataBaseDir, sprintf('histograms_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
% save(outFName, 'H_all', '-ascii');

end






