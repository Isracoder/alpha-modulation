function [Y,U,Mtype,SimulParam] = simul_data(Ns,Im, Mt, flag)

% This function implements a simple model of subjects' responses
% in an active oddball paradigm with varying Inter-Stimulus Intervals (ISI)
% The simulated experiment aims at capturing the effect of non-periodic
% sound sequences on perception and perceptual decisions in terms of
% accuracy and reaction times.
%
% Inputs:
% - Ns indicates the number of simulations or subjects
% - Im indicates which model is used to generate synthetic data
% - flag: if true, launches of sample of the generated auditory stimuli
%
% 28/01/2021 - J. Mattout

%% Experimental design
NBchunk = 50;   % number of chunks (must be even) , default was 150, see if increasing helps accuracy
Ua      = [0 1]; % 2 auditory (std/dev) & 2 visual (nogo/go) stimuli
ISIm    = 600;   % mean ISI in ms
ISIv    = 0.05;  % ISI variance for aperiodic sequences
Chunks  = 3:7;   % chunk size before a go trial

% Generate the sequence of chunk types
Nrep    = NBchunk/2;
Ia      = repmat(Ua,1,Nrep);
Ioa     = randperm(length(Ia));
Itype   = [ones(1,2*Nrep) ; Ia(Ioa)];

% Generate the sequence of chunk sizes
Nrep    = ceil(NBchunk/length(Chunks));
Istim   = repmat(Chunks,Nrep);
Iorder  = randperm(length(Istim));
Isize   = Istim(Iorder);
Isize   = Isize(1:NBchunk);

U = zeros(2,sum(Isize+1)); % first part visual, second part auditory, and tracks ISI
ind = 0;
for i = 1:NBchunk
    U(1,ind+Isize(i)+1) = Itype(1,i); % sets the visual input part as 0 or 1 (no response/response)
    U(2,ind+Isize(i)+1) = Itype(2,i); % sets the auditory input part as 0 or 1 (std/deviant)
    ind = ind + Isize(i) + 1;
end
Nstim = length(U);

% After generating U, check how many go/no go trials (answer required or
% not)
fprintf('Total trials: %d\n', size(U,2));
fprintf('Go trials (U(1,:)==1): %d\n', sum(U(1,:)==1));
fprintf('No-go trials (U(1,:)==0): %d\n', sum(U(1,:)==0));

% Generate the sequence of ISI
switch Im
    case 0 % periodic model
        Uisi = repmat(ISIm,1,Nstim);
        U =[U ; Uisi];
    case 1 % aperiodic model
        Uisi = log(ISIm) + sqrt(ISIv)*randn(1,Nstim);
        U =[U ; exp(Uisi)];
end

% Sound play (over 20 seconds)
if flag
    Fs = 8000;
    Lseq = 20; % sequence length in seconds
    Us = zeros(1,Fs*Lseq);
    StimDur = 30;  % stimulus duration in ms
    StimInt = 1;   % stimulus intensity
    Step = Fs/1000;
    Is = U(3,:)*Step;
    Is = cumsum(Is);
    Is = Is((Is+Step*StimDur)<Fs*Lseq);
    for i = 1:length(Is)
        %disp("range") ;
        %disp(Is(i)) ; % these numbers are complex scientific ones which is
        %why I get the console warnings
        %disp(Is(i)+Step*StimDur) ;

        Us(Is(i):Is(i)+Step*StimDur) = StimInt;
    end
    T    = 1/Fs;
    t    = 0:T:Lseq;
    t(1) = [];
    snd  = 0.2*cos(2*pi*440*t);
    Uz   = smooth(Us.*snd);
    sound(Uz,Fs);
end


%% Model definitions

% using log since it'll later be exp transformed as precision should be positive
pU = log(16);      % sensory precision, how much weight to give to current incoming sensory data, higher precision is more reliability and less variance
pX = log(8);       % prior precision, how `` `` to give to learned expectations, higher priors means slower updating/changing of beliefs
mu = ISIm;         % prior mean ISI  % this also induces high accuracy


Pobs = [5, 10, 0.1, 1, 0]' ; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
%Sobs = 0.01*diag(ones(1,length(Pobs)));

% my assumption [previous posterior mean, previous posterior precision, previous prior mean, previous prior precision, predictive precision , time] , it could be that the predictive precision is the same as the posterior assuming an optimal bayesian learner
X  = [mu log(16) mu log(16) log(16) 0]'; % What is represented by these states ? mean and precision of what ?
%SX = 0.01*diag(ones(1,length(X)));

%Mtype = ['M' num2str(Im)];
% Mtype = 'M1' ;
Mtype = ['M' num2str(Mt)]; % I changed this to use an additional Mt flag to uncouple from Im, seems to have no effect on success rate even with periodic sequence (0 Im) and adaptative model (1 Mt)

switch Mtype
    case 'M0'  % Non adaptive model
        fname  = @f_Audio_H0;
        x0     = X;     %SigmaX0    = SX;
        theta  = pU;    %SigmaTheta = 0.05;
        phi    = Pobs;  %SigmaPhi   = Sobs;
    case 'M1' % Adaptive model
        fname  = @f_Audio_H1;
        x0     = X;            %SigmaX0    = SX;
        theta  = [pU ; pX];    %SigmaTheta = diag([0.05 0.001]);
        phi    = Pobs;         %SigmaPhi   = Sobs;
end

% Response model
gname = @g_Audio_Resp;


%% Data simulation
rng('shuffle');
Y = cell(1,Ns);
SimulParam = struct('theta',[],'phi',[], 'x0', []);
for k = 1:Ns

    disp(['Simulating data for subject ' num2str(k) ' out of ' num2str(Ns) ' subjects']);

    Uk = U;
    nt = length(Uk);
    options.skipf = zeros(1,nt);
    options.skipf(1) = 1;
    alpha = Inf;  % assumes infinite precision and no noise, assumes ground truth in observations, what I observe is exact
    sigma = Inf;  % assumes inf precision no state noise, model is deterministic in evolution and state transitions

    %     Ntheta = length(theta);
    %     Nphi   = length(phi);
    Ptheta = theta;
    Pphi   = phi;
    %     Ptheta = theta + sqrt(diag(SigmaTheta)).*randn(Ntheta,1);
    %     Pphi   = phi + sqrt(diag(SigmaPhi)).*randn(Nphi,1);
    Sx0    = x0;  % initial state vector ? mu values of prior mean ISI, sensory precision , ..

    options.sources(1).out  = 1;
    options.sources(1).type = 1; % first output, choice, is bernouilli binary
    options.sources(2).out  = 2;
    options.sources(2).type = 0;  % second output is RT, a gaussian

    options.inG.PhiOpt = 0;

    % [posterior , out] = VBA_NLStateSpaceModel(y, U , f_name, invert_gname, dim, options) ;
    % % evaluate
    % displayResults(posterior, out, y)



    [y,x, x0, eta, e, u] = VBA_simulate(nt,fname,gname,Ptheta,Pphi,U,alpha,sigma,options,Sx0);

    Y{k} = zeros(2, nt); % I added this isra

    Y{k}(1,:) = y(1,:);
    Y{k}(2,:) = y(2,:);


    SimulParam(k).theta = Ptheta;
    SimulParam(k).x0 = x0;
    SimulParam(k).phi   = Pphi;

end

displaySimulations(y,x,eta,e);




%% Data display and summary statistics

% from q-learning demo

% hf = figure(...
%     'name', 'Simulated behavior', ...
%     'color', 'w' ...
%     ) ;

% ha = axes('parent', hf, 'nextplot', 'add') ;
% plot(ha, y, 'kx')
% plot(ha, y-e, 'r')
% legend(ha, {'y: agent''s choices', 'p(y=1|theta, phi, m): behavioral tendency'})




% Extract go trials (where visual input = 1)
go_trials = find(U(1,:) == 1);


% Initialize arrays for summary stats
accuracy = zeros(1, Ns);
mean_RT_correct = zeros(1, Ns);
std_RT_correct = zeros(1, Ns);

std_RT_error = zeros(1, Ns);
mean_RT_error = zeros(1, Ns);

for k = 1:Ns
    % Calculate accuracy (only on go trials)
    responses = Y{k}(1, go_trials);

    responses(responses == -1) = NaN;  % Exclude no-response trials
    %disp("how many response trials")
    %disp(size(responses(responses ~= -1))) % how many were response trials

    actual_stim = U(2, go_trials);  % 0=standard, 1=deviant
    accuracy(k) = mean(responses == actual_stim, 'omitnan');

    % Calculate mean RT for correct and error trials
    correct_trials = go_trials(responses == actual_stim);
    error_trials = go_trials(responses ~= actual_stim & ~isnan(responses));

    if ~isempty(correct_trials)
        mean_RT_correct(k) = mean(Y{k}(2, correct_trials));
        std_RT_correct(k) = std(Y{k}(2, correct_trials)) ;
    end
    if ~isempty(error_trials)
        mean_RT_error(k) = mean(Y{k}(2, error_trials));
        std_RT_error(k) = std(Y{k}(2, error_trials)) ;
    end
end

% disp(mean_RT_correct(1, Ns)) ;

% Display summary
fprintf('\n=== SIMULATION SUMMARY ===\n');
fprintf('Model: %s\n', Mtype);
fprintf('Number of subjects: %d\n', Ns);
fprintf('Mean accuracy: %.2f%% (SD: %.2f%%)\n', ...
    mean(accuracy)*100, std(accuracy)*100);
fprintf('Mean RT across subjects (correct): %.2f ms (SD: %.2f ms)\n', ...
    mean(mean_RT_correct), std(mean_RT_correct));
fprintf('Mean RT across subjects (error): %.2f ms (SD: %.2f ms)\n', ...
    mean(mean_RT_error), std(mean_RT_error));

fprintf('Mean RT 1st subject (correct): %.2f ms (SD: %.2f ms)\n', ...
    (mean_RT_correct(1)), std_RT_correct(1));
fprintf('Mean RT 1st subject (error): %.2f ms (SD: %.2f ms)\n', ...
    (mean_RT_error(1)), std_RT_error(1));


%% Dummy inversion

% dummy VB inversion (with ideal priors) of volatile learner
% d00 = struct('n',2*5,'n_theta',3,'n_phi',2);
% priors = [];
% priors.muPhi = SimulParam(1).phi    ; % initially give them dummy whatever
% priors.muTheta = SimulParam(1).theta;
% priors.muX0 = x0;
% priors.SigmaPhi = 0*eye(d00.n_phi);
% priors.SigmaTheta = 0*eye(d00.n_theta);
% priors.SigmaX0 = 0*eye(d00.n);
% priors.a_alpha = Inf;
% priors.b_alpha = 0;
% opt00 = options;
% opt00.priors = priors;
% [p00,o00] = VBA_NLStateSpaceModel(y,u,@f_OpLearn,@g_VBvolatile0,d00,opt00);  % how to make sure in inversion that there is no loop

