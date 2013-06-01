function B = update_B(B, x, new_c_KNN, B_feature_selection_idx, iterNum)

% B is a Mxd matrix
% x is a 1xd matrix
% new_c_KNN is a 1xM matrix, gotten from solve_LCC_analytically after feature selection on B_old
% B_feature_selection_idx is the idx of B of the features that we selected after thresholding
% B is the updated Mxd matrix

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