% Load and preprocess training data
% Parameters
fs          = 360;                  % Sample frequency (hertz)
fr          = 60;                   % Frame rate (hertz)
nchannels   = 32;                   % Number of channels (electrodes)
ntrials     = 30;
lentrial    = 2250; 

traincodesfile = 'mgold_61_6521.mat';
datafile = load('training_dataW.mat');

% x = single(zeros(nchannels, lentrial, ntrials)); 
temp = struct2cell(datafile.data);
x = temp{1};

for i = 2:ntrials
    x = cat(3, x, temp{i});
end

traindatafile = single(x); 

trainlabelsfile = [datafile.devents(:).value];
trainsubset     = 1:15;                              % Indices of codes from train set used during training
trainlayout     = 1:15;                              % Indices of codes from train set used during training

% % Testing data
% testdatafile    = traindatafile;                  % The testing data [channels samples testtrials]
% testlabelsfile  = trainlablesfile;                % The labels of the testing data [testtrials 1]
% testcodesfile   = traincodesfile;                   % Code-file used during testing
testsubset      = 1:15;                              % Indices of codes from test set used during testing
testlayout      = 1:15;  



% Preprocessing
prpcfg = struct(...
    'verb',0,...                    % Whether or not to give printed feedback
    'fs',fs,...                     % Sample frequency of the data [hertz]
    'reref','car',...               % Rereferencing method: car: oz, no
    'bands',{{[2 48]}},...          % Spectral filtering pass-bands [hertz]
    'fronttime',0,...               % Baseline time to be removed [seconds]
    'chnthres','3',...              % Threshold to remove channels [#standard deviation]
    'trlthres','3');                % Threshold to remove trials [#standard deviation]

% Classifier
% methods = {'fix','fwd','bwd'};
clfcfg = struct(...
    'verbosity',0,...               % Whether or not to plot the classifier (also manually done)
    'user','S01',...                % E.g., name of the participant of this dataset (just for plotting)
    'fs',fs,...                     % Sample frequency of the data [hertz] (just for plotting)
    'capfile','nt_cap32.loc',...    % Capfile (just for plotting)
    'nclasses',15,...               % Number of classes
    'method','fix',...              % Classifier method: fix (fixed-length), fwd (forward-stopping), bwd (backward-stopping)
    'L',[.3 .3],...                 % Transient response length, individually specified for each event
    'delay',0,...                   % Delay in the hardware marker
    'lx',.9,...                     % Regularization over channels
    'ly','tukey',...                % Regularization over transient responses
    'lxamp',0.1,...                 % Amplitude of regularization
    'lyamp',0.01,...                % Amplitude of regularization
    'subsetV',trainsubset,...       % Subset of training codes
    'subsetU',testsubset,...        % Subset of testing codes
    'layoutV',trainlayout,...       % Layout of training codes
    'layoutU',testlayout,...        % Layout of testing codes
    'stopping','margin',...         % Stopping model: margin, beta
    'segmenttime',.1,...            % Duration of a segment, i.e., time after which the classifier is applied during stopping
    'accuracy',.95,...
    'online',false);                % Targeted accuracy for stopping

% fprintf('Loading and preprocessing training data: %s\n',traindatafile);
disp('preprocessing data..')
% load(fullfile(traindatafile));
%[traindata.X, ret] = jt_preproc_basic_rh(traindatafile(:,:,:),prpcfg); % might need indexing: (2:nchannels+1,:,:)
[traindata.X, ret] = jt_preproc_basic_rh(traindatafile(2:nchannels+1,:,:),prpcfg);
%load(fullfile(trainlabelsfile));
%traindata.y = v(:);
traindata.y = trainlabelsfile;

% Removing unusable trials
for i = 1 : size(traindata.y)  
    if ret.rmvtrl(i) == 1 
        fprintf('trial %i removed\n', i);
        traindata.y(i) = []; 
    end
end

% Removing unusable channels
for i = 1 : size(traindata.X,1)
    if ret.rmvchn(i) == 1
        fprintf('channel %i removed\n', i); 
    end
end

if size(traindata.X,1)~=nchannels; error('Might need channel indexing, change v to v(2:nchannels+1,:,:).'); end

fprintf('\tTraining data: [%d %d %d]\n',size(traindata.X,1),size(traindata.X,2),size(traindata.X,3));

% Generate training codes
fprintf('Generating training codes: %s\n',traincodesfile);
codes = [];
load(traincodesfile);
traincodes = jt_upsample(codes,fs/fr); % upsample from framerate to samplerate
traindata.V = traincodes;
fprintf('\tTraining codes: [%d %d]\n',size(traindata.V,1),size(traindata.V,2));

results = jt_tmc_cv_rh(traindata,clfcfg); 

for i = 2:10
    temp = (results.c(i-1).transients + results.c(i).transients()) ./2;
    results.c(i).transients = results.c(i).transients(:) * ...
    sign(jt_correlation(results.c(i).transients(:),temp));
end

fprintf('Mean accuarcy: %d\n', mean(results.p)); 
fprintf('Mean trial length: %d\n', mean(results.t)); 
fprintf('Mean data length: %d\n', mean(results.d)); 

plots(results, 1, 1)