%% global configurations
DEFAULT_DATASET_TYPE = 'scene';

RESULTS_DIR = 'results';
epsilon = 1e-4;
num_image_batch_size = 100;

%% split_dataset_to_test_train.m configurations
NUM_TRAINING_IMAGES_SCENE = 100;



%% classify.m configurations
% defaults
USE_FEATURE_CACHE_DEFAULT = 1;

% feature configurations
reduce_dictionary = 0;
ndata_max = 100000;
maxImageSize = 1000;
dictionarySize = 400;
numTextonImages = 1000;
pyramidLevels = 4;

gridSpacing = 8;
patchSize = 16;

use_pyramid_match_kernel = 0;
if (use_pyramid_match_kernel)
    use_histogram_intersection_kernel = 1;
    use_pyramid_level_weights = 1;
else
    use_histogram_intersection_kernel = 0;
    use_pyramid_level_weights = 1;          % this doesnt matter if we don't use histogram intersection kernel, so to avoid recomputing all the features again, set this to 1
end
use_LLC = 1;
if (use_LLC)
    code_constraint = 'LLC';
    poolType = 'max';
    poolNormalization = 'L2';
    normalizeD = 1;
    NN_k = 5;
else
    code_constraint = 'VC';
    poolType = 'sum';
    poolNormalization = 'sum';
end

% ext_param_1 governs generating histograms and compiling pyramid
% (concatenating histograms of different scales). Ignores SIFT and
% dictionary.
% force param_1 to be 0 when generating SIFT features and codebook dictionary
ext_param_1 = 10000*use_LLC + 1000*(~strcmp(code_constraint, 'VC')) + 100*(~use_pyramid_level_weights) + 10*(~strcmp(poolType, 'sum')) + (~strcmp(poolNormalization, 'sum'));
ext_param_2 = 0;
ext_param_3 = 0;
ext_param_4 = 0;
ext_param_5 = 0;

