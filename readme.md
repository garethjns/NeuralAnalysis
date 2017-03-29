# NeuralAnalysis

Classes and scripts for analysing temporal (and later spatial) behavioural and neural data.


## Requirements
 - MATLAB 2016b
 - Linspecer
 - [ggraph](https://github.com/garethjns/MATLABGraphicsFunctions)
 - TDT ActiveX Controls
 - TDT Helper
 - [fitPsyche](https://github.com/garethjns/PsychometricCurveFitting)
 - [filtfilthd](https://uk.mathworks.com/matlabcentral/fileexchange/17061-filtfilthd)
 - [CleanData.m](http://www.med.upenn.edu/mulab/programs.html)
 

## Specific classes
  - Subject
    - Imports subject, sets parameters
  - Sessions
    - Finds and imports all behavioural sessions for subject
  - Sess
    - Import behavioural data
    - Analyse behavioural data (using BehavAnalysis and ggraph)
    - Process and link neural data (using Neural and TDT Helper)
  - BehavAnalysis
    - Library of behavioural analysis scripts for different levels
  - Nerual
    - Import and process neural data

