function [train_evaluations test_evaluations test_accuracies c_vals] = classify(dataset_base_dir, use_feature_cache)
startTime = tic;
% dataset_base_dir: the base directory for the image files
% feature_cache_dir: the base directory for the data files that are generated
%  by the features. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image files
% use_feature_cache: uses cached data from the previous run of feature generation

% load config
rng(0);
config;

% set defaults
if(nargin<1)
    dataset_base_dir = get_dataset_base_dir(DEFAULT_DATASET_TYPE);
end
if (nargin<2)
    use_feature_cache = USE_FEATURE_CACHE_DEFAULT;
end

feature_cache_dir = get_feature_cache_base_dir(dataset_base_dir);

[dataset_train_dir dataset_test_dir] = get_dataset_training_test_dirs(dataset_base_dir);
[feature_cache_train_dir feature_cache_test_dir] = get_dataset_training_test_dirs(feature_cache_dir);

filenames_train = get_image_filenames(dataset_train_dir);
filenames_test = get_image_filenames(dataset_test_dir);

% generate dictionary
generate_dictionary(filenames_train, dataset_train_dir, feature_cache_train_dir, feature_cache_test_dir, use_feature_cache);

% train + training evaluation
[training_features training_labels] = compute_features(filenames_train, dataset_train_dir, feature_cache_train_dir, use_feature_cache);
if (use_histogram_intersection_kernel)
    addpath('libsvm-3.17/matlab');
    K_train = [(1:size(training_features,1))', hist_isect_c(training_features, training_features)];
    model = svmtrain(training_labels, K_train, '-t 4');
    [predicted_train_labels, ~, ~] = svmpredict(training_labels, K_train, model);
else 
    addpath('liblinear-1.93/matlab');
    model = train(training_labels, sparse(training_features));
    [predicted_train_labels, ~, ~] = predict(training_labels, sparse(training_features), model);
end
[train_evaluation] = evaluate(predicted_train_labels, training_labels);

% test - make predictions
[testing_features testing_labels] = compute_features(filenames_test, dataset_test_dir, feature_cache_test_dir, use_feature_cache);
if (use_histogram_intersection_kernel)
    K_test = [(1:size(testing_features,1))', hist_isect_c(testing_features, training_features)];
    [predicted_test_labels, ~, ~] = svmpredict(testing_labels, K_test, model); 
else
    [predicted_test_labels, ~, ~] = predict(testing_labels, sparse(testing_features), model);
end
[test_evaluation] = evaluate(predicted_test_labels, testing_labels);

train_evaluation
test_evaluation

date_and_time = clock;
y = int64(date_and_time(1));
m = int64(date_and_time(2));
d = int64(date_and_time(3));
hh = int64(date_and_time(4));
mm = int64(date_and_time(5));
ss = int64(date_and_time(6));

dataset_name = dataset_base_dir;
dataset_name(dataset_name=='/')='-';
outFName = [RESULTS_DIR '/' sprintf('%d-%d-%d_%d:%d:%d_%s_eval_%d_%d_%d_%d_%d_%d_ext_%d_%d_%d_%d_%d.mat', y, m, d, hh, mm ,ss, dataset_name, use_histogram_intersection_kernel, dictionarySize, numTextonImages, pyramidLevels, gridSpacing, patchSize, ext_param_1, ext_param_2, ext_param_3, ext_param_4, ext_param_5)];
save(outFName, 'train_evaluation', 'test_evaluation'); 


train_evaluations = [];
test_evaluations = [];
test_accuracies = [];
c_vals = [0.01, 0.05, 0.1, 0.3, 0.5, 0.75, 1, 2, 5, 10, 15, 20, 50, 100, 500, 1000, 5000, 10000];
for i=1:length(c_vals)
    c = c_vals(i)
    if (use_histogram_intersection_kernel)
        opt = ['-q -t 4 -c ' num2str(c)];
        model = svmtrain(training_labels, K_train, opt);
        [predicted_train_labels, ~, ~] = svmpredict(training_labels, K_train, model);
        [predicted_test_labels, ~, ~] = svmpredict(testing_labels, K_test, model);
    else
        opt = ['-q -c ' num2str(c)];
        model = train(training_labels, sparse(training_features), opt);
        [predicted_train_labels, ~, ~] = predict(training_labels, sparse(training_features), model);
        [predicted_test_labels, ~, ~] = predict(testing_labels, sparse(testing_features), model);
        
    end
    
    [train_evaluation] = evaluate(predicted_train_labels, training_labels)
    [test_evaluation] = evaluate(predicted_test_labels, testing_labels)
    
    train_evaluations = [train_evaluations; train_evaluation];
    test_evaluations = [test_evaluations; test_evaluation];
    test_accuracies = [test_accuracies; test_evaluation.mean_class_accuracy];
end

endTime = toc(startTime)
end

function [filenames] = get_image_filenames(image_dir)
fnames = dir(fullfile(image_dir, '*.jpg'));
num_files = size(fnames,1);
filenames = cell(num_files,1);

for f = 1:num_files
   filenames{f} = fnames(f).name;
end
end
