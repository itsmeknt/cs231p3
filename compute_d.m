function d = compute_d(X, B, sigma)

% N is a Nxd vector
% B is a Mxd matrix
% sigma is a real number
% d is a NxM matrix. It is zeros if sigma <= 0

if (sigma <= 0)
    d = zeros(size(X,1), size(B,1));
    return;
end

config;

Xtensor = reshape(X, size(X,1), 1, size(X,2));   % Nx1xd dim
Btensor = reshape(B, 1, size(B,1), size(B,2));   % 1xMxd dim
diff = bsxfun(@minus, Xtensor, Btensor);         % NxMxd dim
dist = sum(diff.*diff, 3);                       % NxMx1 dim

% reshape tensor to matrix
dist = reshape(dist, size(dist,1), size(dist,2));   % NxM dim

if (normalizeD)
    % normalize
    dist = bsxfun(@minus, dist, max(dist,2));      % NxM dim
end

d = exp(dist/sigma);   % NxM dim
end