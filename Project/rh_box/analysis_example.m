% Example analysis script for Noise-Tagging. Trains a template matching
% classifier using a bag of training data, and applies it to another bag of
% testing data. Then prints and plots the results.
% 
% NOTES
% - Specify your specific paths to the training data, testing data
% - Specify which training and testing codes you have used, as well as
%   the subset and layout for these
% - Specify the data samplefrequency (fs) and stimulation frequency (fr)
% - Specify the perprocessing options
% - Specify the classifier options: note that the classifier in this
%   example is trained for backwards-stopping, but is applied performing
%   fixed-length, forward-stopping, as well as backward-stopping trials


%% RESET
restoredefaultpath;
clear variables;
close all;
clc;
root = '~';
addpath(fullfile(root,'bci_code','own_experiments','visual','noise_tagging','jt_box'));
jt_set_paths(root);

%% SETTINGS

% Training data
traindatafile   = '~/Downloads/traintrials.mat';    % The training data [channels samples traintrials]
trainlabelsfile = '~/Downloads/trainlabels.mat';    % The labels of the training data [traintrials 1]
traincodesfile  = 'mgold_61_6521_flip_balanced.mat';              % Code-file used during training
trainsubset     = 1:4;                              % Indices of codes from train set used during training
trainlayout     = 1:4;                              % Indices of codes from train set used during training

% Testing data
testdatafile    = '~/Downloads/traintrials.mat';    % The testing data [channels samples testtrials]
testlabelsfile  = '~/Downloads/trainlabels.mat';    % The labels of the testing data [testtrials 1]
testcodesfile   = 'mgold_61_6521_flip_balanced.mat';              % Code-file used during testing
testsubset      = 1:4;                              % Indices of codes from test set used during testing
testlayout      = 1:4;                              % Indices of codes from test set used during testing

% Parameters
fs          = 360;                  % Sample frequency (hertz)
fr          = 60;                   % Frame rate (hertz)
iti         = 2;                    % Inter-trial interval (seconds)
nchannels   = 32;                   % Number of channels (electrodes)

% Preprocessing
prpcfg = struct(...
    'verb',0,...            % Whether or not to give printed feedback
    'fs',fs,...             % Sample frequency of the data [hertz]
    'reref','car',...       % Rereferencing method: car: oz, no
    'bands',{{[2 48]}},...  % Spectral filtering pass-bands [hertz]
    'fronttime',0,...       % Baseline time to be removed [seconds]
    'chnthres','no',...     % Threshold to remove channels [#standard deviation]
    'trlthres','no');       % Threshold to remove trials [#standard deviation]

% Classifier
methods = {'fix','fwd','bwd'};
clfcfg = struct(...
    'verbosity',1,...   % Whether or not to plot the classifier (also manually done)
    'user','S01',...    % E.g., name of the participant of this dataset (just for plotting)
    'fs',fs,...         % Sample frequency of the data [hertz] (just for plotting)
    'capfile','nt_cap32.loc',... % Capfile (just for plotting)
    'nclasses',4,...   % Number of classes
    'method','bwd',...  % Classifier method: fix (fixed-length), fwd (forward-stopping), bwd (backward-stopping)
    'L',[.3 .3],...     % Transient response length, individually specified for each event
    'delay',0,...       % Delay in the hardware marker
    'lx',.9,...         % Regularization over channels
    'ly','tukey',...    % Regularization over transient responses
    'lxamp',0.1,...     % Amplitude of regularization
    'lyamp',0.01,...    % Amplitude of regularization
    'subsetV',trainsubset,...   % Subset of training codes
    'subsetU',testsubset,...    % Subset of testing codes
    'layoutV',trainlayout,...   % Layout of training codes
    'layoutU',testlayout,...    % Layout of testing codes
    'stopping','margin',...     % Stopping model: margin, beta
    'segmenttime',.1,...        % Duration of a segment, i.e., time after which the classifier is applied during stopping
    'accuracy',.95);            % Targeted accuracy for stopping

%% INITIALIZATION

% Load and preprocess training data
fprintf('Loading and preprocessing training data: %s\n',traindatafile);
load(fullfile(traindatafile));
traindata.X = jt_preproc_basic(v(2:nchannels+1,:,:),prpcfg); % might need indexing: (2:nchannels+1,:,:)
if size(traindata.X,1)~=nchannels; error('Might need channel indexing, change v to v(2:nchannels+1,:,:).'); end
load(fullfile(trainlabelsfile));
traindata.y = v(:);
fprintf('\tTraining data: [%d %d %d]\n',size(traindata.X,1),size(traindata.X,2),size(traindata.X,3));

% Load and preprocess testing data
fprintf('Loading and preprocessing testing data: %s\n',testdatafile);
load(fullfile(testdatafile));
testdata.X = jt_preproc_basic(v(2:nchannels+1,:,:),prpcfg); % might need indexing: (2:nchannels+1,:,:)
if size(testdata.X,1)~=nchannels; error('Might need channel indexing, change v to v(2:nchannels+1,:,:).'); end
load(fullfile(testlabelsfile));
testdata.y = v(:);
fprintf('\tTesting data: [%d %d %d]\n',size(testdata.X,1),size(testdata.X,2),size(testdata.X,3));

% Generate training codes
fprintf('Generating training codes: %s\n',traincodesfile);
codes = [];
load(traincodesfile);
traincodes = jt_upsample(codes,fs/fr); % upsample from framerate to samplerate
traincodes = repmat(traincodes,[ceil(size(traindata.X,2)/size(traincodes,1)) 1]); % repeat to full trial length
traindata.V = traincodes(1:size(traindata.X,2),:);
fprintf('\tTraining codes: [%d %d]\n',size(traindata.V,1),size(traindata.V,2));

% Generate testing codes
fprintf('Generating testing codes: %s\n',testcodesfile);
codes = [];
load(testcodesfile);
testcodes = jt_upsample(codes,fs/fr); % upsample from framerate to samplerate
testcodes = repmat(testcodes,[ceil(size(testdata.X,2)/size(testcodes,1)) 1]); % repeat to full trial length
traindata.U = testcodes(1:size(testdata.X,2),:);
fprintf('\tTesting codes: [%d %d]\n',size(traindata.U,1),size(traindata.U,2));

%% TRAINING
fprintf('Training classifier\n');

% Train classifier
classifier = jt_tmc_train(traindata,clfcfg);

% View classifier
%jt_tmc_view(classifier);

%% TESTING
fprintf('Testing classifier\n');
p = zeros(numel(methods),1);
t = zeros(numel(methods),1);
d = zeros(numel(methods),1);
for i = 1:numel(methods)
    
    % Set specific method to use
    classifier.cfg.method = methods{i};
    
    % Apply classifier
    [y,ret] = jt_tmc_apply(classifier,testdata.X);
    
    % Save results
    p(i) = mean(y==testdata.y); % Mean accuracy
    t(i) = mean(ret.t);         % Mean trial length
    d(i) = mean(ret.d);         % Mean data length
end
itr = jt_itr(classifier.cfg.nclasses,p,t+iti);

%% RESULTS

% Print results
for i = 1:numel(methods)
    fprintf('Method: %s\n',methods{i});
    fprintf('\tp:\t%1.2f\n',p(i));
    fprintf('\tt:\t%1.2f\n',t(i));
    fprintf('\td:\t%1.2f\n',d(i));
    fprintf('\titr:\t%1.2f\n',itr(i));
end

% Plot results
figure();
subplot(4,1,1); bar(p*100); ylabel('Accuracy [%]'); set(gca,'xticklabel',[]);
subplot(4,1,2); bar(t); ylabel('Duration [sec]'); set(gca,'xticklabel',[]);
subplot(4,1,3); bar(d); ylabel('Length [sec]'); set(gca,'xticklabel',[]);
subplot(4,1,4); bar(itr); ylabel('ITR [bit/min]'); set(gca,'xticklabel',methods);

