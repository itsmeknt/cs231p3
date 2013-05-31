function [ H_all ] = BuildHistograms( imageFileList, dataBaseDir, featureSuffix, canSkip )
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
fprintf('Building Histograms\n\n');

%% parameters

if(nargin<4)
    dictionarySize = 200
end

if(nargin<5)
    numTextonImages = 50
end

if(nargin<6)
    canSkip = 0
end

%% Check cache
outFName = fullfile(dataBaseDir, sprintf('histograms_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages,ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
if (size(dir(outFName), 1) ~= 0)
    return;
end


%% load texton dictionary (all texton centers)

inFName = fullfile(dataBaseDir, sprintf('dictionary_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
load(inFName,'dictionary');
fprintf('Loaded texton dictionary: %d textons\n', dictionarySize);

%% compute texton labels of patches and whole-image histograms
H_all = [];

for f = 1:size(imageFileList,1)

    imageFName = imageFileList{f};
    [dirN base] = fileparts(imageFName);
    baseFName = fullfile(dirN, base);
    inFName = fullfile(dataBaseDir, sprintf('%s%s', baseFName, featureSuffix));
    
    outFName = fullfile(dataBaseDir, sprintf('%s_texton_ind_%d_%d_ext_%d_%d_%d_%d_%d.mat', baseFName, dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
    outFName2 = fullfile(dataBaseDir, sprintf('%s_hist_%d_%d_ext_%d_%d_%d_%d_%d.mat', baseFName, dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
        
    if(size(dir(outFName),1)~=0 && size(dir(outFName2),1)~=0 && canSkip)
        fprintf('Skipping %s\n', imageFName);
        load(outFName2, 'H');
        H_all = [H_all; H];
        continue;
    end
    
    %% load sift descriptors
    load(inFName, 'features');
    ndata = size(features.data,1);
    fprintf('Loaded %s, %d descriptors\n', inFName, ndata);

    %% find texton indices and compute histogram 
    texton_ind.data = zeros(ndata,1);
    texton_ind.x = features.x;
    texton_ind.y = features.y;
    texton_ind.wid = features.wid;
    texton_ind.hgt = features.hgt;
    %run in batches to keep the memory foot print small
    batchSize = 10000;
    if ndata <= batchSize
        dist_mat = sp_dist2(features.data, dictionary);
        [min_dist, min_ind] = min(dist_mat, [], 2);
        texton_ind.data = min_ind;
    else
        for j = 1:batchSize:ndata
            lo = j;
            hi = min(j+batchSize-1,ndata);
            dist_mat = dist2(features.data(lo:hi,:), dictionary);
            [min_dist, min_ind] = min(dist_mat, [], 2);
            texton_ind.data(lo:hi,:) = min_ind;
        end
    end

    H = hist(texton_ind.data, 1:dictionarySize);
    H_all = [H_all; H];

    %% save texton indices and histograms
    save(outFName, 'texton_ind');
    save(outFName2, 'H');
end

%% save histograms of all images in this directory in a single file
outFName = fullfile(dataBaseDir, sprintf('histograms_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
save(outFName, 'H_all', '-ascii');


end
