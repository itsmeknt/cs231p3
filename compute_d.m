function d = compute_d(x, B, sigma, normalizeD)

% x is a 1xd vector
% B is a Mxd matrix
% sigma is a real number
% d is a 1xM matrix. It is zeros if sigma <= 0

if (sigma <= 0)
    d = zeros(1, size(B,1));
    return;
end

diff = bsxfun(@minus, B, x);
dist = sqrt(sum(diff.*diff, 2));                       % Mx1 dim

if (normalizeD)
    % normalize
    dist = dist-max(dist);      % Mx1 dim
end

d = exp(dist/sigma);   % NxM dim
end