#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon May 29 20:07:29 2023

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
import scipy.io as scio
import shap


# dataset = scio.loadmat('/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集/mDataTableS_GEMS_train.mat')["mDataTableS_GEMS"]
dataset = scio.loadmat('/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集_1023/mDataTableS_GEMS_train.mat')["mDataTableS_GEMS"]
# dataset = scio.loadmat('/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集_sp/mDataTableS_GEMS_train.mat')["mDataTableS_GEMS"]
savepath = '/data01/sg/2023-静止卫星臭氧光化学反演/分析出图/shap/'
# dataset = scio.loadmat('/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集/mDataTableS_GEMS_train_HCHOfilter.mat')["mDataTableS_GEMS_HCHOfilter"]
# 11:12 SRTM, NDVI
# 14:21 meteorological: t2 d2 sp u10 v10 tp e RH
# 23:25 NO2: NO2,O3,SZA
# 27:30 HCHO&UV: HCHO,uncertainty, UV,photo
# 32 GRD_O3
# 33:34 DOY,WK
# dataset = dataset[dataset[:,7]!=11,:]
# dataset = dataset[dataset[:,12]>-1,:]
# dataset = dataset[dataset[:,11]<3000,:]
dataset = dataset[dataset[:,14]>-9999,:]
dataset = dataset[dataset[:,15]>-9999,:]
dataset = dataset[dataset[:,16]>-9999,:]
dataset = dataset[dataset[:,17]>-9999,:]
dataset = dataset[dataset[:,18]>-9999,:]
dataset = dataset[dataset[:,12]>-3,:]

dataset = dataset[dataset[:,7]<11,:]

data = dataset[:, [9,11,12,14,15,16,17,18,19,20,21,23,29,33]]
data = dataset[:, [14,15,16,17,18,19,20,21,23,27,29,33,6,9,11,12]]

target = dataset[:, [32]]

# 将参数写成字典下形式
params = {
    'task': 'train',
    'boosting_type': 'gbdt',  # 设置提升类型
    'objective': 'regression',  # 目标函数
    'metric': {'rmse'},  # 评估函数
    'num_leaves': 1200,  # 叶子节点数 1200
    'max_depth': 20,  # -1
    'learning_rate': 0.05,  # 学习速率 0.05
    'feature_fraction': 0.99,  # 建树的特征选择比例 0.75
    'bagging_fraction': 0.99,  # 建树的样本采样比例 0.75
    'bagging_freq': 1,  # k 意味着每 k 次迭代执行bagging
    'verbose': -1,  # <0 显示致命的, =0 显示错误 (警告), >0 显示信息
    'n_jobs': 16
}

# 十折交叉验证
folds = KFold(n_splits=10, shuffle=True, random_state=1)
applyset =  np.zeros((data.shape[0],dataset.shape[1]))
predset = np.zeros((data.shape[0]))
testset = np.zeros((data.shape[0]))
predictions = np.zeros((len(target)))
lgb_importance = []
r = []
rmse = []


for fold_, (trn_idx, val_idx) in enumerate(folds.split(data, target)):
    print("fold n°{}".format(fold_ + 1))
    print(data[trn_idx].shape, type(data))
    x_tr, y_tr = data[trn_idx], target[trn_idx]
    x_va, y_va = data[val_idx], target[val_idx]

    trn_data = lgb.Dataset(x_tr, y_tr)
    val_data = lgb.Dataset(x_va, y_va, reference=trn_data)

    clf = lgb.train(params, trn_data, num_boost_round=3000, valid_sets=val_data, early_stopping_rounds=50,
                    verbose_eval=50)  # 训练数据需要参数列表和数据集

    y_pred = clf.predict(x_va, num_iteration=clf.best_iteration)
    y_test = y_va.flatten()
    
    # 评估模型
    print('The rmse of prediction is:', mean_squared_error(y_test, y_pred) ** 0.5)  # 计算真实值和预测值之间的均方根误差
    print('The R2 of prediction is:', r2_score(y_test, y_pred, multioutput='raw_values'))  # 计算真实值和预测值之间的R2
    
    predset[val_idx] = clf.predict(x_va, num_iteration=clf.best_iteration)
    testset[val_idx] = y_va.flatten()
    applyset[val_idx] = dataset[val_idx]
    lgb_importance.append(clf.feature_importance())
    r.append(r2_score(y_test, y_pred, multioutput='raw_values'))
    rmse.append(mean_squared_error(y_test, y_pred) ** 0.5)

print('Final rmse of prediction is:', np.mean(r))  # 计算真实值和预测值之间的均方根误差
print('Final R2 of prediction is:', np.mean(rmse))  # 计算真实值和预测值之间的R2
print('Final rmse of prediction is:', mean_squared_error(testset, predset) ** 0.5)  # 计算真实值和预测值之间的均方根误差
print('Final R2 of prediction is:', r2_score(testset, predset, multioutput='raw_values'))  # 计算真实值和预测值之间的R2 

applyset = np.c_[applyset,testset]
applyset = np.c_[applyset,predset]
dataNew = '/data01/sg/2023-静止卫星臭氧光化学反演/中间数据/applyset_sp.mat'

scio.savemat(dataNew, {'applyset':applyset})

