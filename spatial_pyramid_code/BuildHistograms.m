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
    texton_ind.data = zeros(dictionarySize, ndata);
    texton_ind.x = features.x;
    texton_ind.y = features.y;
    texton_ind.wid = features.wid;
    texton_ind.hgt = features.hgt;
    %run in batches to keep the memory foot print small
    batchSize = 10000;
    if ndata <= batchSize
        if (strcmp(code_constraint, 'VC')
            dist_mat = sp_dist2(features.data, dictionary);
            [min_dist, min_ind] = min(dist_mat, [], 2);
            row = min_ind;
            col = 1:length(min_ind);
            texton_ind.data(sub2ind(size(texton_ind.data),row,col)) = 1;
        elseif (strcmp(code_constraint, 'LLC'))
        end
    else
        for j = 1:batchSize:ndata
            if (strcmp(code_constraint, 'VC')
                lo = j;
                hi = min(j+batchSize-1,ndata);
                dist_mat = dist2(features.data(lo:hi,:), dictionary);
                [min_dist, min_ind] = min(dist_mat, [], 2);
                row = min_ind;
                col = 1:length(min_ind);
                texton_ind.data(sub2ind(size(texton_ind.data),row,col)) = 1;
            elseif (strcmp(code_constraint, 'LLC'))
            end
        end
    end

    % H = hist(texton_ind.data, 1:dictionarySize);
    % H_all = [H_all; H];

    %% save texton indices and histograms
    save(outFName, 'texton_ind');
    % save(outFName2, 'H');
end


%% save histograms of all images in this directory in a single file
% outFName = fullfile(dataBaseDir, sprintf('histograms_%d_%d_ext_%d_%d_%d_%d_%d.mat', dictionarySize, numTextonImages, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5));
% save(outFName, 'H_all', '-ascii');

end

% N is a Nxd vector
% B is a Mxd matrix
% sigma is a real number
% d is a NxM matrix. It is zeros if sigma <= 0
function d = compute_d(X, B, sigma)
if (sigma <= 0)
    d = zeros(size(X,1), size(B,1));
    return;
end

config;

Xtensor = reshape(X, size(X,1), 1, size(X,2));   % Nx1xd dim
Btensor = reshape(B, 1, size(B,1), size(B,2));   % 1xMxd dim
diff = bsxfun(@minus, Xtensor, Btensor);         % NxMxd dim
dist = sum(diff.*diff, 3);                       % NxMx1 dim

% reshape tensor to matrix
dist = reshape(dist, size(dist,1), size(dist,2));   % NxM dim

if (normalizeD)
    % normalize
    dist = disxfun(@minus, dist, max(dist,2));      % NxM dim
end

d = exp(dist/sigma);   % NxM dim
end

% x is a 1xd vector
% B is a Mxd vecror
% lambda is a real number
% sigma is a real number
% codes is a 1xM matrix
function c = solve_LLC_analytically(x, B, lambda, sigma)
cov_half = B-(ones(size(x,1),1)*x);                     % Mxd dim
cov = cov_half*cov_half;                                 % MxM dim

d = compute_d(x, B, sigma);             % 1xM dim
c_tilda = (cov + lambda*diag(d.^2)) \ ones(size(cov,1), size(cov,2));                                 % MxM dim

c = (c_tilda/ones(1, size(cov,2))'*c_tilda;                                       % 1xM dim
end

% x is a 1xd matrix
% B is a Mxd matrix
% lambda is a real number
% sigma is a real number
% c is a 1xM matrix
function c = solve_LCC_KNN(x, B, lambda, sigma)
config;
B_small_knn = knnsearch(B,x,'k',NN_k,'NSMethod','exhaustive','distance','euclidean');
B_small_idx = unique(B_small_knn(:));
B_small = B(B_small_idx, :);            % kxd matrix

c_small = solve_LLC_analytically(x, B_small, 0, 0);    % 1xk matrix. Lambda and sigma = 0 because we lose the locality term in the reduced form

c = zeros(1, size(B,1));
c(B_small_idx) = c_small;
end

% B is a Mxd matrix
% x is a 1xd matrix
% new_c_KNN is a 1xM matrix, gotten from solve_LCC_analytically after feature selection on B_old
% B_feature_selection_idx is the idx of B of the features that we selected after thresholding
% B is the updated Mxd matrix
function B = update_B(B_feature_selected, x, new_c_KNN, B_feature_selection_idx, iterNum)
B_feature_selected = B(B_feature_selection_idx, :);                     % mxd
delta_B_fs = (-2*(x'-B_feature_selected'*new_c_KNN')*new_c_KNN)';       % mxd

mu = sqrt(1/iterNum);
B_new_fs = B_feature_selected - mu*delta_B_fs'/sqrt(new_c_KNN*new_c_KNN');  % mxd

check = unique(find(sqrt(sum(B_new_fs.*B_new_fs,2))==0));
if length(check) > 1 || check == 1
    error('B_new_fs when projecting onto unit sphere, found denominator 0');
end

% project onto unit circle
B_new_fs = bsxfun(@rdivide, B_new_fs, sqrt(sum(B_new_fs.*B_new_fs,2)));     % mxd

B(B_feature_selection_idx,:) = B_new_fs;
end
