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


dataset = scio.loadmat('/.../')["mDataTableS_TROPOMI"]
# 11:12 SRTM, NDVI
# 14:21 meteorological: t2 d2 sp u10 v10 tp e RH
# 23:25 NO2: NO2,O3,SZA
# 27:30 HCHO&UV: HCHO,uncertainty, UV,photo
# 32 GRD_O3
# 33:34 DOY,WK
# dataset = dataset[dataset[:,7]!=11,:]
dataset = dataset[dataset[:,13]>0,:]

data = dataset[:, [10,11,13,14,15,16,17,18,19,20,22,24,25,33]]

target = dataset[:, [27]]


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

    clf = lgb.train(params, trn_data, num_boost_round=1000, valid_sets=val_data, early_stopping_rounds=50,
                    verbose_eval=50) 

    y_pred = clf.predict(x_va, num_iteration=clf.best_iteration)
    y_test = y_va.flatten()
    
    # model evaluation
    print('The rmse of prediction is:', mean_squared_error(y_test, y_pred) ** 0.5) 
    print('The R2 of prediction is:', r2_score(y_test, y_pred, multioutput='raw_values')) 
    
    predset[val_idx] = clf.predict(x_va, num_iteration=clf.best_iteration)
    testset[val_idx] = y_va.flatten()
    applyset[val_idx] = dataset[val_idx]
    lgb_importance.append(clf.feature_importance())
    r.append(r2_score(y_test, y_pred, multioutput='raw_values'))
    rmse.append(mean_squared_error(y_test, y_pred) ** 0.5)
    # break
print('Final rmse of prediction is:', np.mean(r))  
print('Final R2 of prediction is:', np.mean(rmse))  
print('Final rmse of prediction is:', mean_squared_error(testset, predset) ** 0.5)  
print('Final R2 of prediction is:', r2_score(testset, predset, multioutput='raw_values'))  

applyset = np.c_[applyset,testset]
applyset = np.c_[applyset,predset]

dataNew = '/.../'
clf.save_model('/.../model_all.txt')

scio.savemat(dataNew, {'applyset':applyset})




