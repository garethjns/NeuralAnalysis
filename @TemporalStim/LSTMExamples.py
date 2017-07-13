# -*- coding: utf-8 -*-
"""
Created on Mon Jul 10 13:50:29 2017

@author: Gareth
"""

#%%
import scipy.io as sio
import matplotlib.pyplot as plt
import numpy as np

from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Embedding
from keras.layers import LSTM

from sklearn.preprocessing import minmax_scale as MMS


#%% Load data

def loadMat(fn):
    f = sio.loadmat(fn)
    events = f['events'].astype(np.int16)
    sounds = f['sounds'].astype(np.float16)
    rates = MMS(f['rates'].squeeze())
    
    return events, sounds, rates

events, sounds, rates = loadMat('stimData_500x1178.mat')

idx = np.random.randint(events.shape[0])
plt.plot(sounds[idx,:])
plt.plot(events[idx,:])
plt.show()
print(rates[idx])

xTrain = sounds[0:350,:]
yTrain = events[0:350,:]
yTrainR = rates[0:350]

xTest = sounds[350::,:]
yTest = sounds[350::,:]
yTestR = rates[350::]


# Needed when extracting sequence from LSTM layers
xTrainExp = np.expand_dims(xTrain, axis=2)
xTestExp = np.expand_dims(xTest, axis=2)
yTrainExp = np.expand_dims(yTrain, axis=2)
yTestExp = np.expand_dims(yTest, axis=2)


def evalMod(model, xTrain, xTest):
    yPred = model.predict(xTrain)
    
    idx = np.random.randint(yPred.shape[0])
    plt.plot(sounds[idx,:])
    plt.plot(events[idx,:])
    plt.plot(yPred[idx,:])
    plt.show()
    print(rates[idx])
    
    
    yPredTest = model.predict(xTest)
    
    idx = np.random.randint(yPredTest.shape[0])
    plt.plot(sounds[idx+350,:])
    plt.plot(events[idx+350,:])
    plt.plot(yPred[idx,:])
    plt.show()
    print(rates[idx])

    return yPred, yPredTest


def evalRegMod(model, xTrain, xTest):
    yPred = model.predict(xTrain)
    
    idx = np.random.randint(yPred.shape[0])
    plt.plot(sounds[idx,:])
    plt.plot(events[idx,:])
    plt.plot(yPred[idx,:])
    plt.show()
    print('Training pred.')
    print('Pred:', yPred[idx])
    print('GT:', rates[idx])
    
    
    yPredTest = model.predict(xTest)
    
    idx = np.random.randint(yPredTest.shape[0])
    plt.plot(sounds[idx+350,:])
    plt.plot(events[idx+350,:])
    plt.plot(yPred[idx,:])
    plt.show()
    print('Test pred.')
    print('Pred:', yPred[idx])
    print('GT:', rates[idx])

    return yPred, yPredTest    
    
    
#%% Define models

def simpleLSTM(data, nPts=128):
    
    timeSteps = data.shape[1]
    
    model = Sequential()
    model.add(Embedding(timeSteps, output_dim=timeSteps))
    model.add(LSTM(nPts))
    model.add(Dropout(0.5))
    model.add(Dense(timeSteps, activation='tanh'))
    
    model.compile(loss='mse',
                  optimizer='rmsprop',
                  metrics=['accuracy'])

    return model


def simpleLSTMSequence(data):
    
    timeSteps = data.shape[1]
    dim3 = data.shape[2]
    
    model = Sequential()
    # model.add(Embedding(294, output_dim=294))
    model.add(LSTM(128, return_sequences=True, input_shape=(timeSteps, dim3)))
    # model.add(LSTM(64, return_sequences=True, input_shape=(xTrainExp.shape[1], xTrainExp.shape[2])))
    model.add(Dropout(0.5))
    model.add(Dense(1, activation='sigmoid'))
    
    
    model.compile(loss='binary_crossentropy',
                  optimizer='rmsprop',
                  metrics=['accuracy'])
    
    return model


def complexLSTMSequence(data):
    
    timeSteps = data.shape[1]
    dim3 = data.shape[2]
    
    model = Sequential()
    # model.add(Embedding(294, output_dim=294))
    model.add(LSTM(128, return_sequences=True, input_shape=(timeSteps, dim3)))
   
    model.add(Dropout(0.5))
    model.add(Dense(1, activation='sigmoid'))
    model.add(LSTM(64, return_sequences=True, input_shape=(timeSteps, dim3)))
    model.add(Dropout(0.5))
    model.add(Dense(1, activation='sigmoid'))
    
    model.compile(loss='binary_crossentropy',
                  optimizer='rmsprop',
                  metrics=['accuracy'])
    
    return model


def complexLSTMSequence2(data):
    
    timeSteps = data.shape[1]
    dim3 = data.shape[2]
    
    model = Sequential()
    # model.add(Embedding(294, output_dim=294))
    model.add(LSTM(128, return_sequences=True, input_shape=(timeSteps, dim3)))
    model.add(LSTM(64, return_sequences=True, input_shape=(timeSteps, dim3)))
    model.add(LSTM(64)) 
    model.add(Dropout(0.5))
    model.add(Dense(timeSteps, activation='sigmoid'))
    
    model.compile(loss='binary_crossentropy',
                  optimizer='rmsprop',
                  metrics=['accuracy'])

    return model
    

#%% Set 1, model 1

model1 = simpleLSTM(xTrain)
model1.fit(xTrain, yTrain, batch_size=4, epochs=10)

score = model1.evaluate(xTest, yTest, batch_size=4)


yPred, yPredTest = evalMod(model1, xTrain, xTest)


#%% Set 1, model 2
# Return sequences directly from LSTM


model2 = simpleLSTMSequence(xTrainExp)    
model2.fit(xTrainExp, yTrainExp, batch_size=16, epochs=10)
score = model2.evaluate(xTestExp, yTestExp, batch_size=16)

yPred, yPredTest = evalMod(model2, xTrainExp, xTestExp)


#%% Set 1, model 3
# Return sequences directly from LSTM


model3 = complexLSTMSequence(xTrainExp)
    
model3.fit(xTrainExp, yTrainExp, batch_size=16, epochs=10)
score = model3.evaluate(xTestExp, yTestExp, batch_size=16)

yPred, yPredTest = evalMod(model3, xTrainExp, xTestExp)



#%% Set 1, model 4
# Based on example, LSTM layers follow each other


model4 = complexLSTMSequence2(xTrainExp)
model4.fit(xTrainExp, yTrain, batch_size=16, epochs=10)
score = model4.evaluate(xTestExp, yTest, batch_size=16)

yPred, yPredTest = evalMod(model4, xTrainExp, xTestExp)


#%% Create stacked sequential LSTM event detector (from examples)
#https://keras.io/getting-started/sequential-model-guide/

#%% Create simple sequential LSTM event detector


#%% load bigger data set

events, sounds, rates = loadMat('stimData_500x1178.mat')

xTrain = sounds[0:350,:]
yTrain = events[0:350,:]
yTrainR = rates[0:350]

xTest = sounds[350::,:]
yTest = sounds[350::,:]
yTestR = rates[350::]


# Needed when extracting sequence from LSTM layers
xTrainExp = np.expand_dims(xTrain, axis=2)
xTestExp = np.expand_dims(xTest, axis=2)
yTrainExp = np.expand_dims(yTrain, axis=2)
yTestExp = np.expand_dims(yTest, axis=2)


#%% Set 2, model 1

model1 = simpleLSTM(xTrain, nPts=32)
model1.fit(xTrain, yTrain, batch_size=16, epochs=15)

score = model1.evaluate(xTest, yTest, batch_size=16)

yPred, yPredTest = evalMod(model1, xTrain, xTest)


#%% Set 2, model 2
# Return sequences directly from LSTM


model2 = simpleLSTMSequence(xTrainExp)    
model2.fit(xTrainExp, yTrainExp, batch_size=16, epochs=10)
score = model2.evaluate(xTestExp, yTestExp, batch_size=16)

yPred, yPredTest = evalMod(model2, xTrainExp, xTestExp)


#%% Set 2, model 3
# Return sequences directly from LSTM


model3 = complexLSTMSequence(xTrainExp)
    
model3.fit(xTrainExp, yTrainExp, batch_size=16, epochs=10)
score = model3.evaluate(xTestExp, yTestExp, batch_size=16)

yPred, yPredTest = evalMod(model3, xTrainExp, xTestExp)



#%% Set 2, model 4
# Based on example, LSTM layers follow each other


model4 = complexLSTMSequence2(xTrainExp)
model4.fit(xTrainExp, yTrain, batch_size=16, epochs=10)
score = model4.evaluate(xTestExp, yTest, batch_size=16)

yPred, yPredTest = evalMod(model4, xTrainExp, xTestExp)


#%% More models

def simpleLSTMReg(data, nPts=32):
    
    timeSteps = data.shape[1]
    
    model = Sequential()
    model.add(Embedding(timeSteps, output_dim=timeSteps))
    model.add(LSTM(nPts))
    model.add(Dropout(0.5))
    model.add(Dense(timeSteps, activation='relu'))
    model.add(Dense(int(timeSteps/2), activation='relu'))
    model.add(Dense(1, activation='relu'))
    
    model.compile(loss='mae',
                  optimizer='adam',
                  metrics=['accuracy'])

    return model
    
model5 = simpleLSTMReg(xTrain, nPts=8)
model5.fit(xTrain, yTrainR, batch_size=16, epochs=3)

score = model5.evaluate(xTest, yTestR, batch_size=16)

yPred, yPredTest = evalRegMod(model5, xTrain, xTest)
