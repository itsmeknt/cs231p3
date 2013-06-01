function c = solve_LLC_analytically(x, B, lambda, sigma, epsilon)

% x is a 1xd vector
% B is a Mxd vecror
% lambda is a real number
% sigma is a real number
% codes is a 1xM matrix

cov_half = B-(ones(size(B,1),1)*x);                     % Mxd dim
cov = cov_half*cov_half' + epsilon*diag(ones(size(cov_half,1),1));                                 % MxM dim

d = compute_d(x, B, sigma);             % 1xM dim
c_tilda = (cov + lambda*diag(d.^2)) \ ones(size(cov,1), 1);                                 % Mx1 dim

c = c_tilda/sum(c_tilda);                                       % Mx1 dim
end