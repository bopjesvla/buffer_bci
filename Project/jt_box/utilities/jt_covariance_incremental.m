function [avg_new, cov_new, m_new] = jt_covariance_incremental(obs, avg_old, cov_old, m_old)

m_obs = size(obs, 1);
avg_obs = mean(obs, 1);

% Sample count
m_new = m_obs + m_old;

% First data
if m_old <= 0

    % Average
    avg_new = avg_obs;

    % Zero mean
    x1 = bsxfun(@minus, obs, avg_obs);

    % Covariance
    cov_obs = x1' * x1;
    cov_new = cov_obs / (m_new - 1);

% Update
else

    % Average
    avg_new = avg_old + (avg_obs - avg_old) * (m_obs / m_new);

    % Zero mean
    x1 = bsxfun(@minus, obs, avg_old);
    x2 = bsxfun(@minus, obs, avg_new);

    % Covariance
    cov_obs = x1' * x2;
    cov_new = cov_obs / (m_new - 1) + cov_old * ((m_old - 1) / (m_new - 1));

end

function test_case()

m = 360*4*60;
n = 100;
step = 360/2;
X = double(rand(m, n));

% Incremental
avg_inc = [];
cov_inc = [];
m_inc = 0;
for i = 1:m/step
    obs = X(1 + (i-1) * step:i * step, :);
    [avg_inc, cov_inc, m_inc] = jt_covariance_incremental(obs, avg_inc, cov_inc, m_inc);
end

% Non-incremental
X = bsxfun(@minus, X, mean(X, 1));
cov_noninc = cov(X);

disp(max(abs(cov_inc(:) - cov_noninc(:))));

disp(m_inc-m);