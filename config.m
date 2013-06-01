%% global configurations
rng(0);
DEFAULT_DATASET_TYPE = 'scene';

RESULTS_DIR = 'results';

%% split_dataset_to_test_train.m configurations
NUM_TRAINING_IMAGES_SCENE = 100;



%% classify.m configurations
% defaults
USE_FEATURE_CACHE_DEFAULT = 1;

% feature configurations
reduce_dictionary = 1;
ndata_max = 100000;

maxImageSize = 1000;
dictionarySize = 400;
numTextonImages = 1000;
pyramidLevels = 4;

gridSpacing = 8;
patchSize = 16;

use_pyramid_match_kernel = 1;
if (use_pyramid_match_kernel)
    use_histogam_intersection_kernel = 1;
    use_pyramid_level_weights = 1;
else
    use_histogam_intersection_kernel = 0;
    use_pyramid_level_weights = 0;
end
use_LLC = 0;
if (use_LLC)
    code_constraint = 'LLC';
    poolType = 'max';
    poolNormalization = 'L2';
else
    code_constraint = 'VC';
    poolType = 'sum';
    poolNormalization = 'sum';
end
ext_param_1 = use_LLC;
ext_param_2 = strcmp(code_constraint, 'VC');
ext_param_3 = ~use_pyramid_level_weights;
ext_param_4 = strcmp(poolType, 'sum');
ext_param_5 = strcmp(poolNormalization, 'sum');


%% add paths
addpath('spatial_pyramid_code');
if (use_histogram_intersection_kernel)
    addpath('libsvm-3.17/matlab');
else
    addpath('liblinear-1.93/matlab');
end
