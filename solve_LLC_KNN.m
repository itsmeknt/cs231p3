function c = solve_LLC_KNN(x, B, B_knn_idxs, epsilon, normalizeD)
% x is a 1xd matrix
% B is a Mxd matrix
% B_knn_idxs are the indices of B that are nearest to x according to KNN
% epsilon is a real number
% normalizeD is binary

B_small = B(B_knn_idxs, :);            % kxd matrix

c_small = solve_LLC_analytically(x, B_small, 0, 0, epsilon, normalizeD);    % 1xk matrix. Lambda and sigma = 0 because we lose the locality term in the reduced form

c = zeros(1, size(B,1));
c(B_knn_idxs) = c_small;
end