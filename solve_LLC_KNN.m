function c = solve_LLC_KNN(x, B, B_knn_idxs, epsilon)
% x is a 1xd matrix
% B is a Mxd matrix
% lambda is a real number
% sigma is a real number
% c is a 1xM matrix

B_small = B(B_knn_idxs, :);            % kxd matrix

c_small = solve_LLC_analytically(x, B_small, 0, 0, epsilon);    % 1xk matrix. Lambda and sigma = 0 because we lose the locality term in the reduced form

c = zeros(1, size(B,1));
c(B_knn_idxs) = c_small;
end