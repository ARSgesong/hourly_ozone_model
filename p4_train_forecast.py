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

dataset = scio.loadmat('/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集_Forecast/mDataTableS_GEMS_train_MDA8')["mDataTableS_GEMS"]

dataset = dataset[dataset[:,14]>-9999,:]
dataset = dataset[dataset[:,15]>-9999,:]
dataset = dataset[dataset[:,16]>-9999,:]
dataset = dataset[dataset[:,17]>-9999,:]
dataset = dataset[dataset[:,18]>-9999,:]
dataset = dataset[dataset[:,12]>-3,:]
dataset = dataset[dataset[:,68]>0,:]
dataset = dataset[dataset[:,69]>0,:]
dataset = dataset[dataset[:,70]>0,:]
dataset = dataset[dataset[:,75]>0,:]
dataset = dataset[dataset[:,76]>0,:]
dataset = dataset[dataset[:,77]>0,:]
dataset = dataset[dataset[:,72]>0,:]
dataset = dataset[dataset[:,73]>0,:]
dataset = dataset[dataset[:,74]>0,:]
dataset = dataset[dataset[:,86]>0,:]
dataset = dataset[dataset[:,87]>0,:]
dataset = dataset[dataset[:,88]>0,:]
dataset = dataset[dataset[:,89]>0,:]
dataset = dataset[dataset[:,90]>0,:]
dataset = dataset[dataset[:,91]>0,:]
data = dataset[:, [14,15,16,17,18,19,20,21,23,24,25,26,27,28,29,30,
                   32,33,34,35,36,37,38,39,41,42,43,44,45,46,47,48,
                   50,51,52,53,54,55,56,57,59,60,61,62,63,64,65,66,
                   68,69,70,72,73,74,75,76,77,9,11,12,93,94]]

target = dataset[:, [91]]

params = {
    'task': 'train',
    'boosting_type': 'gbdt', 
    'objective': 'regression',  
    'metric': {'rmse'},  
    'num_leaves': 1200, 
    'max_depth': 20, 
    'learning_rate': 0.05,  
    'feature_fraction': 0.99,  
    'bagging_fraction': 0.99,  
    'bagging_freq': 1, 
    'verbose': -1,  
    'n_jobs': 16
}

# cross-validation
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
                    verbose_eval=50) 

    y_pred = clf.predict(x_va, num_iteration=clf.best_iteration)
    y_test = y_va.flatten()
    
    # model performance
    print('The rmse of prediction is:', mean_squared_error(y_test, y_pred) ** 0.5) 
    print('The R2 of prediction is:', r2_score(y_test, y_pred, multioutput='raw_values')) 
    
    predset[val_idx] = clf.predict(x_va, num_iteration=clf.best_iteration)
    testset[val_idx] = y_va.flatten()
    applyset[val_idx] = dataset[val_idx]
    lgb_importance.append(clf.feature_importance())
    r.append(r2_score(y_test, y_pred, multioutput='raw_values'))
    rmse.append(mean_squared_error(y_test, y_pred) ** 0.5)
    
print('Final rmse of prediction is:', np.mean(r))  
print('Final R2 of prediction is:', np.mean(rmse)) 
print('Final rmse of prediction is:', mean_squared_error(testset, predset) ** 0.5)  
print('Final R2 of prediction is:', r2_score(testset, predset, multioutput='raw_values'))  

applyset = np.c_[applyset,testset]
applyset = np.c_[applyset,predset]

clf.save_model('/.../model.txt')




