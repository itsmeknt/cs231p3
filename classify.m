function [train_evaluation test_evaluation] = classify(dataset_base_dir, feature_cache_dir, use_feature_cache)

% dataset_base_dir: the base directory for the image files
% feature_cache_dir: the base directory for the data files that are generated
%  by the features. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image files
% use_feature_cache: uses cached data from the previous run of feature generation

% load config
config;

% set defaults
if(nargin<1)
    dataset_base_dir = get_dataset_base_dir(DEFAULT_DATASET_TYPE);
end
if(nargin<2)
    feature_cache_dir = get_feature_cache_base_dir(dataset_base_dir);
end
if (nargin<3)
    use_feature_cache = USE_FEATURE_CACHE_DEFAULT;
end

[dataset_train_dir dataset_test_dir] = get_dataset_training_test_dirs(dataset_base_dir);
[feature_cache_train_dir feature_cache_test_dir] = get_dataset_training_test_dirs(feature_cache_dir);

filenames_train = get_image_filenames(dataset_train_dir);
filenames_test = get_image_filenames(dataset_test_dir);

% train - generate dictionary, learn svm model
generate_dictionary(filenames_train, dataset_train_dir, feature_cache_train_dir, feature_cache_test_dir, use_feature_cache);
[training_features training_labels] = compute_features(filenames_train, dataset_train_dir, feature_cache_train_dir, use_feature_cache);
model = train(training_labels, sparse(training_features));

% train evaluation
[predicted_train_label, ~, ~] = predict(training_labels, sparse(training_features), model);
[train_evaluation] = evaluate(predicted_train_label, training_labels);

% test - make predictions
[testing_features testing_labels] = compute_features(filenames_test, dataset_test_dir, feature_cache_test_dir, use_feature_cache);
[predicted_test_label, ~, ~] = predict(testing_labels, sparse(testing_features), model);

[test_evaluation] = evaluate(predicted_test_label, testing_labels);
end

function [filenames] = get_image_filenames(image_dir)
fnames = dir(fullfile(image_dir, '*.jpg'));
num_files = size(fnames,1);
filenames = cell(num_files,1);

for f = 1:num_files
   filenames{f} = fnames(f).name;
end
end