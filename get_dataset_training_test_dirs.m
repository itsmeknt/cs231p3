function [dataset_training_dir dataset_test_dir] = get_dataset_training_test_dirs(dataset_dir)

dataset_training_dir = [dataset_dir '/train'];
dataset_test_dir = [dataset_dir '/test'];

end

