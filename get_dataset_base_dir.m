function [dataset_dir] = get_dataset_base_dir(dataset_type)

if (strcmp(dataset_type, 'scene'))
    dataset_dir = 'datasets/scene';
elseif (strcmp(dataset_type, 'ppmi'))
    dataset_dir = 'datasets/ppmi';
else
    err = MException(['get_dataset_base_dir error: dataset_type "' ...
        dataset_type '" not supported! Currently only support "scene"' ...
        ' and "ppmi"']);
    throw(err);
end

end

