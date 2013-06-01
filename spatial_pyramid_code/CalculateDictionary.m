function [dictionary] = CalculateDictionary( imageFileList, dataBaseDir, featureSuffix, numCodewords, canSkip, writeFile )
%function [Dictionary] = CalculateDictionary( imageFileList, dataBaseDir, featureSuffix, dictionarySize, numTextonImages, canSkip )
%
%Create the texton dictionary
%
% First, all of the sift descriptors are loaded for a random set of images. The
% size of this set is determined by numTextonImages. Then k-means is run
% on all the descriptors to find N centers, where N is specified by
% dictionarySize.
%
% imageFileList: cell of file paths
% dataBaseDir: the base directory for the data files that are generated
%  by the algorithm. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image files.
% featureSuffix: this is the suffix appended to the image file name to
%  denote the data file that contains the feature textons and coordinates. 
%  Its default value is '_sift.mat'.
% dictionarySize: size of descriptor dictionary (200 has been found to be
%  a good size)
% numTextonImages: number of images to be used to create the histogram
%  bins
% canSkip: if true the calculation will be skipped if the appropriate data 
%  file is found in dataBaseDir. This is very useful if you just want to
%  update some of the data or if you've added new images.
% Dictionary - Mxd matrix

config;
% duplicate variables because parfor complains otherwise
copy_num_image_batch_size = num_image_batch_size;

fprintf('Building Dictionary\n\n');

outFName = fullfile(dataBaseDir, sprintf('dictionary_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, 0, ext_param_2, ext_param_3, ext_param_4, ext_param_5));

if(numTextonImages > size(imageFileList,1))
    numTextonImages = size(imageFileList,1);
end

if(size(dir(outFName),1)~=0 && canSkip)
    fprintf('Dictionary file %s already exists.\n', outFName);
    return;
end
    

%% load file list and determine indices of training images

inFName = fullfile(dataBaseDir, 'f_order.txt');
if ~isempty(dir(inFName))
    R = load(inFName, '-ascii');
    if(size(R,1)~=size(imageFileList,1))
        R = randperm(size(imageFileList,1));
        sp_make_dir(inFName);
        save(inFName, 'R', '-ascii');
    end
else
    %{
    imageFileIdxByClass = cell(0,1);
    for i=1:size(imageFileList,1)
        imageFName = imageFileList{i};
        classIdx = get_class_label(imageFName);
        if (length(imageFileIdxByClass) < classIdx || isempty(imageFileIdxByClass{classIdx}))
            imageFileIdxByClass{classIdx} = i;
        else
            imageFileIdxByClass{classIdx} = [imageFileIdxByClass{classIdx}; i];
        end
    end
    
    R = [];
    numFilesLeft = size(imageFileList,1);
    while (numFilesLeft > 0)
        for i=1:length(imageFileIdxByClass)
            classIdxList = imageFileIdxByClass{i};
            if (~isempty(classIdxList))
                % get last element
                R = [R; classIdxList(end)];
                classIdxList(end) = [];
                
                numFilesLeft=numFilesLeft-1;
            end
        end
    end
    %}

    use_pyramid_match_kernel = 0;
    sp_make_dir(inFName);
    save(inFName, 'R', '-ascii');
end

training_indices = R(1:numTextonImages);

%% load all SIFT descriptors

% just load a random one to get the dimensionality of SIFT features
imageFName = imageFileList{training_indices(1)};
[dirN base] = fileparts(imageFName);
baseFName = fullfile(dirN, base);
inFName = fullfile(dataBaseDir, sprintf('%s%s', baseFName, featureSuffix));

allVar = load(inFName, 'features');
features = allVar.features;
ndata = size(features.data,1);
dim_data = size(features.data,2);

% load all sift features onto sift_al
sift_all = [];
    
num_batches = ceil(size(imageFileList,1)/num_image_batch_size);
for batch_idx = 1:num_batches
    entries_per_batch = min(copy_num_image_batch_size, numTextonImages-copy_num_image_batch_size*(batch_idx-1));
    if (numTextonImages < copy_num_image_batch_size)
        entries_per_batch = numTextonImages;
    end
    
    sift_all_batch = cell(entries_per_batch, 1);
    parfor entry_idx = 1:entries_per_batch
        imageFName = imageFileList{training_indices(entry_idx+copy_num_image_batch_size*(batch_idx-1))};
        
        [dirN base] = fileparts(imageFName);
        baseFName = fullfile(dirN, base);
        inFName = fullfile(dataBaseDir, sprintf('%s%s', baseFName, featureSuffix));
        
        allVar = load(inFName, 'features');
        features = allVar.features;
        
        sift_all_batch{entry_idx} = features.data;
        fprintf('Loaded CalcuateDictionary %s, %d descriptors, %d so far\n', inFName, size(features.data,1), entry_idx+copy_num_image_batch_size*(batch_idx-1));
    end
    
    totalPatches = 0;
    for entry_idx=1:entries_per_batch
        totalPatches=totalPatches+size(sift_all_batch{entry_idx},1);
    end
    
    entries_per_batch_dense = zeros(totalPatches, dim_data);
    patchCounter = 0;
    for entry_idx=1:entries_per_batch
        currSift = sift_all_batch{entry_idx};
        numPatches = size(currSift,1);
        entries_per_batch_dense(patchCounter+1:patchCounter+numPatches, :) = currSift;
        patchCounter=patchCounter+numPatches;
    end
    sift_all = [sift_all; entries_per_batch_dense];
end

fprintf('\nTotal descriptors loaded: %d\n', size(sift_all,1));

ndata = size(sift_all,1);    
if (reduce_dictionary > 0) && (ndata > ndata_max)
    fprintf('Reducing to %d descriptors\n', ndata_max);
    p = randperm(ndata);
    sift_all = sift_all(p(1:ndata_max),:);
end
        
%% perform clustering
options = foptions;
options(1) = 1; % display
options(2) = 1;
options(3) = 0.1; % precision
options(5) = 1; % initialization
options(14) = 100; % maximum iterations

centers = zeros(numCodewords, size(sift_all,2));

%% run kmeans
fprintf('\nRunning k-means\n');
dictionary = sp_kmeans(centers, sift_all, options);     % Mxd dim

if (writeFile)
    fprintf('Saving texton dictionary\n');
    sp_make_dir(outFName);
    save(outFName, 'dictionary');
else
    fprintf('Skipping saving texton dictionary\n');
end

end
