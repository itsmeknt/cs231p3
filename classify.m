function [mean_accuracy confusion_matrix] = classify(dataset_base_dir, feature_cache_dir, use_feature_cache)

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
fnames = dir(fullfile(dataset_base_dir, '*.jpg'));
num_files = size(fnames,1);
filenames = cell(num_files,1);

for f = 1:num_files
   enames{f} = fnames(f).name;
end

% train - generate dictionary, learn svm model
generate_dictionary(filenames, dataset_train_dir, feature_cache_train_dir, use_feature_cache);
[training_features training_labels] = compute_features(filenames, dataset_train_dir, feature_cache_train_dir, use_feature_cache);
model = train(training_labels, training_features);

% test - make predictions
[testing_features testing_labels] = compute_features(filenames, dataset_test_dir, feature_cache_test_dir, use_feature_cache);
[predicted_label, accuracy, decision_values/prob_estimates] = predict(testing_labels, testing_features, model);


%% TODO: split to separate file: get_class_label in compilepyramid, get_class_accuracies and get_confusion_matrix in classify
[class_accuracies class_list] = get_class_accuracies(predicted_label, testing_labels);
mean_accuracy =  mean(class_accuracies);
[confusion_matrix class_list2] = get_confusion_matrix(predicted_label, testing_labels);

ASSERT_TRUE = class_list==class_list2
end

function [class_accuracies class_list] = get_class_accuracies(predicted_label, true_label)
class_list = unique([predicted_label; true_label]);
class_accuracies = zeros(length(class_list), 1);
for i=1:length(class_list)
   curr_class = class_list(i);
   true_class_binary = (true_label == curr_class);
   num_class = sum(true_class_binary);
   
   predicted_class_binary = (predicted_label == curr_class);
   num_correct_class = sum(predicted_class_binary & true_class_binary);
   
   class_accuracies(i) = num_correct_class/num_class;
end
end

function [confusion_matrix, class_list] = get_confusion_matrix(predicted_label, true_label)
class_list = unique([predicted_label; true_label]);
confusion_matrix = zeros(length(class_list), length(class_list));
for i=1:length(class_list)
   curr_true_class = class_list(i);
   true_class_binary = (true_label == curr_true_class);
   
   for j=1:length(class_list)
      curr_predicted_class = class_list(i);
      predicted_class_binary = (predicted_label == curr_predicted_class);
      
      confusion_matrix[i][j] = sum(true_class_binary & predicted_class_binray);
   end
end
end
