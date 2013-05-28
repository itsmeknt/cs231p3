%% global configurations
addpath(spatial_pyramid_code);

rng(0);
DEFAULT_DATASET_TYPE = 'scene';

%% split_dataset_to_test_train.m configurations
NUM_TRAINING_IMAGES_SCENE = 100;



%% classify.m configurations
% defaults
USE_FEATURE_DEFAULT = 1;

% feature configurations
maxImageSize = 1000;
dictionarySize = 200;
numTextonImages = 50;
pyramidLevels = 4;

gridSpacing = 8;
patchSize = 16;
