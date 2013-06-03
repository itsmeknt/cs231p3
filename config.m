%% global configurations
DEFAULT_DATASET_TYPE = 'scene';

RESULTS_DIR = 'results';
epsilon = 0;
num_image_batch_size = 500;

%% split_dataset_to_test_train.m configurations
NUM_TRAINING_IMAGES_SCENE = 100;



%% classify.m configurations
% defaults
USE_FEATURE_CACHE_DEFAULT = 1;

% feature configurations
reduce_dictionary = 1;
ndata_max = 100000;
maxImageSize = 1024;
dictionarySize = 1024;
numTextonImages = 1000;
pyramidLevels = 4;

gridSpacing = 8;
patchSize = 16;


use_LLC = 1;
if (use_LLC)
    code_constraint = 'LLC';
    poolType = 'max';
    poolNormalization = 'L2';
    normalizeD = 1;
    NN_k = 6;
    use_pyramid_match_kernel = 0;
    
    use_learned_dictionary = 0;
    dictionary_learning_max_iter = 1;
    significant_code_threshold = 0.01;
    
    LLC_lambda = 20;
    LLC_sigma = 8;
else
    code_constraint = 'VC';
    poolType = 'sum';
    poolNormalization = 'sum';
    use_pyramid_match_kernel = 1;
    use_learned_dictionary = 0;
end

if (use_pyramid_match_kernel)
    use_histogram_intersection_kernel = 1;
    use_pyramid_level_weights = 1;
else
    use_histogram_intersection_kernel = 0;
    use_pyramid_level_weights = 1;          % this doesnt matter if we don't use histogram intersection kernel, so to avoid recomputing all the features again, set this to 1
end

balance_dictionary_training = 0;

% ext_param_1 governs generating histograms and compiling pyramid
% (concatenating histograms of different scales). Ignores SIFT and
% dictionary.
% force param_1 to be 0 when generating SIFT features and codebook dictionary
ext_param_1 = 10000*use_LLC + 1000*(~strcmp(code_constraint, 'VC')) + 100*(~use_pyramid_level_weights) + 10*(~strcmp(poolType, 'sum')) + (~strcmp(poolNormalization, 'sum'));   % last 3 terms are for legacy reasons, should actually be removed
if (NN_k ~= 5)
    ext_param_1 = ext_param_1 + 1e5*NN_k;
end

% ext_param_2 governs codebook generation, so it also affects
% computeHistogram and CompilePyramid, but not SIFT
ext_param_2_k_means = balance_dictionary_training;
ext_param_2 = 10*use_learned_dictionary + ext_param_2_k_means;

% ext_param_3 governs SIFT feature generation, so it affects all the
% functions
ext_param_3 = 100*patchSize + gridSpacing;
if (patchSize == 16)
    ext_param_3 = ext_param_3 - 100*patchSize;
end
if (gridSpacing == 8)
    ext_param_3 = ext_param_3 - gridSpacing;
end

% ext_param_4 governs compiling pyramid only
ext_param_4 = 100*(~use_pyramid_level_weights) + 10*(~strcmp(poolType, 'sum')) + (~strcmp(poolNormalization, 'sum'));
ext_param_5 = 0;

