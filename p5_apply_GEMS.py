 #!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Dec 22 22:10:07 2022

@author: songg
"""

import json
import lightgbm as lgb
import pandas as pd
from scipy import io
import h5py
import numpy as np
from sklearn import metrics
from sklearn.metrics import mean_squared_error
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.model_selection import KFold
from sklearn.datasets import make_classification
from sklearn.metrics import r2_score
from sklearn.utils import shuffle
import hdf5storage
import shap
import scipy.io as scio
import os


clf = lgb.Booster(model_file='/data01/sg/2023-静止卫星臭氧光化学反演/模型保存/model_all.txt')
# clf = lgb.Booster(model_file='/data01/sg/2023-静止卫星臭氧光化学反演/模型保存/model_all_1101.txt')

filepath = '/data01/sg/2023-静止卫星臭氧光化学反演/匹配数据集_卫星全_0711/'
savepath = '/data01/sg/2023-静止卫星臭氧光化学反演/应用数据集_卫星全_1101/'
filelist = os.listdir(filepath)

params = {
    'task': 'train',
    'boosting_type': 'gbdt',  # 设置提升类型
    'objective': 'regression',  # 目标函数
    'metric': {'rmse'},  # 评估函数
    'num_leaves': 1200,  # 叶子节点数 1200
    'max_depth': 20,  # -1
    'learning_rate': 0.03,  # 学习速率 0.05
    'feature_fraction': 0.99,  # 建树的特征选择比例 0.75
    'bagging_fraction': 0.99,  # 建树的样本采样比例 0.75
    'bagging_freq': 1,  # k 意味着每 k 次迭代执行bagging
    'verbose': -1,  # <0 显示致命的, =0 显示错误 (警告), >0 显示信息
    'n_jobs': 64
}

for file in filelist[1212:1250]:
    print(file)
    file_ob=filepath + file
    applyset = io.loadmat(file_ob)["pMatchData"]
    # applyset = applyset[applyset[:,12]>-1,:]
    # applyset = applyset[applyset[:,11]<3000,:]
    applyset = applyset[applyset[:,14]>-9999,:]
    applyset = applyset[applyset[:,15]>-9999,:]
    applyset = applyset[applyset[:,16]>-9999,:]
    applyset = applyset[applyset[:,17]>-9999,:]
    applyset = applyset[applyset[:,18]>-9999,:]
    applyset = applyset[applyset[:,12]>-3,:]
    # x_va = applyset[:,[9,11,12,14,15,16,17,18,19,20,21,23,29,33]]
    x_va = applyset[:,[14,15,16,17,18,19,20,21,23,27,29,33,6,9,11,12]]
    
    # x_va[:,11] = x_va[:,11]*1.1
    y_pred = clf.predict(x_va, num_iteration=clf.best_iteration)
    applyset = np.c_[applyset,y_pred]
    # dataNew = savepath + 'add_' + file
    dataNew = savepath + file
    scio.savemat(dataNew, {'applyset':applyset})