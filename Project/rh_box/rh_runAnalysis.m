%% DESCRIPTION
% This script runs the analysis of the transient responses and the spatial 
% filters for Robin de Heer's bachelor thesis project (noisetagging colors)

%% RESET
clear variables; 
close all;
clc;

%% CREATING, LOADING and REARRANGING DATA
% [resultsBW, resultsBG, resultsBY, resultsRG, resultsRY ] = rh_getResults();

load('resultsBW.mat')
load('resultsBG.mat')
load('resultsBY.mat')
load('resultsRG.mat')
load('resultsRY.mat')

results = {resultsBW, resultsBG, resultsBY, resultsRG, resultsRY}; 

%% PLOTS
rh_plotTransients(results); 
rh_plotFilters(results); 