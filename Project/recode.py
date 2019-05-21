import scipy.io as sio

mat = sio.loadmat('mgold_61_6521.mat')
codes = mat['codes']

mat['codes'] = codes[:, [0, 2, 1, 3] + [0] * 61]
print(mat['codes'].shape)
sio.savemat('codes4.mat', mat)

mat['codes'] = codes[:, [0, 3, 6, 9, 12, 1, 4, 7, 10, 13, 2, 5, 8, 11, 14] + [0] * 50]
print(mat['codes'].shape)
sio.savemat('codes15.mat', mat)

