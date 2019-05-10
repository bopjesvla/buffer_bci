import numpy as np


def streaming_cov(x, avg_old=None, cov_old=None, m_old=0.0):
    m_old = float(m_old)
    m_obs = float(x.shape[0])
    
    avg_obs = np.mean(x, 0)

    m_new = m_old + m_obs

    if m_old <= 0.0:

        avg_new = avg_obs

        x1 = x - avg_obs

        cov_obs = np.dot(x1.T, x1)

        newweight = m_new - 1.0 # why -1?
        cov_new = cov_obs / newweight

    else:

        avg_new = avg_old + (avg_obs - avg_old) * (m_obs / m_new)

        x1 = x - avg_old
        x2 = x - avg_new

        cov_obs = np.dot(x1.T, x2) # why not x2'x2?

        newweight = m_new - 1.0 # why -1?
        cov_new = cov_old * (m_old - 1.0) / newweight + cov_obs / newweight

    return avg_new, cov_new, m_new

# Create data
m = 360*60*4
n = 100
step = 360/2
data = (10 * np.random.rand(m, n)).astype("float64")

# Normal covariance
normal_cov = np.cov(data, rowvar=False)

# Incremental covariance
update_cov = (None, None, 0.0)
for i in range(0, m, step):
    update_cov = streaming_cov(data[i:i+step, :], *update_cov)

# Normal
print(normal_cov)

# Incremental
print(update_cov[1])

# Difference
print(update_cov[1] - normal_cov)