function [Y1,U,SimulParam2, Mtype, Gtype] = simul_data(Ns,Im, Mt, Gt,  flag)

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

%% Experiment

% generate input
% [U_Predictable, ISIm_pred] = generate_input(true, true, 1) ; % currently have this be auditory and predictable, later more dynamic with Im being passed in to influence predictability
[U_Unpredictable, ISIm_unpred] = generate_input(true, false, 1) ;
% [U_B] = generate_input(true, false, 2, false) ; % t unpredictable ,s unpredictable, for paradigm B

% Sound play (over 20 seconds)
if flag
    % play_sound(U_Predictable) ;
    % pause(0.1); % 100ms, (0.01 is 10 ms)
    % play_sound(U_Unpredictable) ; % how to make sure sounds don't intersect ?
end

%% Model definitions

% using log since it'll later be exp transformed as precision should be positive
pU = log(16);      % sensory precision, how much weight to give to current incoming sensory data, higher precision is more reliability and less variance
pX = log(8);       % prior precision, how `` `` to give to learned expectations, higher priors means slower updating/changing of beliefs
mu = 450 ;         % prior mean isi, can have it be based on distribution or not
% mu = log(ISIm_pred ) + sqrt(0.3)*randn(1,1);         % prior mean ISI  % was ISIm changed to random from distributions, this also induces high accuracy
% variance added

% my assumption [previous posterior mean, previous posterior precision, previous prior mean, previous prior precision, predictive precision , time] , it could be that the predictive precision is the same as the posterior assuming an optimal bayesian learner
X  = [mu log(16) mu log(16) log(16) 0]';
%SX = 0.01*diag(ones(1,length(X)));

Mtype = ['M' num2str(Mt)]; % I changed this to use an additional Mt flag to uncouple from Im, seems to have no effect on success rate even with periodic sequence (0 Im) and adaptative model (1 Mt)

switch Mtype
    case 'M0'  % Non adaptive model, assumes fixed gaussian
        fname  = @learning.f_Audio_H0;
        x0     = X;     %SigmaX0    = SX;
        theta  = pU;    %SigmaTheta = 0.05;
    case 'M1' % Adaptive model, can assume shifting gaussian
        fname  = @learning.f_Audio_H1;
        x0     = X;            %SigmaX0    = SX;
        theta  = [pU ; pX];    %SigmaTheta = diag([0.05 0.001]);

    case 'M2' % My Adaptive model, can assume shifting gaussian
        fname  = @learning.f_Audio_modified;
        x0     = X;            %SigmaX0    = SX;
        theta  = [pU ; pX];    %SigmaTheta = diag([0.05 0.001]);
    otherwise
        error("unsupported")

end

[gname , phi, Pobs, mx_ind_neural_models] = set_obs_model(Gt) ;

%% Data simulation
rng('shuffle');

% % run same two simulations but only difference is P vs UP input data
% [Y1 , SimulParam1] = simulate(U_Predictable, Ns, Pobs, theta, phi, x0,  Gt, mx_ind_neural_models, fname, gname, nt) ;
% [Y2 , SimulParam2] = simulate(U_Unpredictable, Ns, Pobs, theta, phi, x0,  Gt, mx_ind_neural_models, fname, gname, nt) ;

% %% Plotting
% calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2) ;

% if (Gt <= mx_ind_neural_models)
%     calculate_plot_neural(Ns, Mtype, Gt,  U_Predictable, Y1 , U_Unpredictable , Y2) ;
% elseif (Gt == 7) % the default one embedded with both neural and choice now
%     calculate_plot_neural(Ns, Mtype, Gt,  U_Predictable, Y1 , U_Unpredictable , Y2) ;
%     calculate_plot_choices(Ns, Mtype, U_Predictable, Y1 , U_Unpredictable , Y2) ;
% else
%     calculate_plot_choices(Ns, Mtype, U_Predictable, Y1 , U_Unpredictable , Y2) ;

% end


end


%% Helper functions (subfunctions)

function [Y, SimulParams] = simulate(U, Ns, Pobs, theta, phi, x0,  Gt, mx_ind_neural_models, fname, gname, nt)
Y = cell(1,Ns); % for predictable case
SimulParams = struct('theta',[],'phi',[], 'x0', [], 'Pobs', Pobs);

for k = 1:Ns % currently for each subject and then can do for each subject and each model

    disp(['Simulating data for subject ' num2str(k) ' out of ' num2str(Ns) ' subjects']);

    Uk = U;
    nt = length(Uk);
    options.skipf = zeros(1,nt);
    options.skipf(1) = 1;
    % alpha = Inf;  % assumes infinite precision and no noise, assumes ground truth in observations, what I observe is exact
    % sigma = Inf;  % assumes inf precision no state noise, model is deterministic in evolution and state transitions
    % sigma = [Inf Inf] ;
    % here I changed this to inf of 2 since I have two gaussian observation params to avoid error in vba simulate

    %     Ntheta = length(theta);
    %     Nphi   = length(phi);
    Ptheta = theta;
    Pphi   = phi;
    %     Ptheta = theta + sqrt(diag(SigmaTheta)).*randn(Ntheta,1);
    %     Pphi   = phi + sqrt(diag(SigmaPhi)).*randn(Nphi,1);
    Sx0    = x0;  % initial state vector ? mu values of prior mean ISI, sensory precision , ..

    options.sources(1).out  = 1;
    % noise = Inf ;
    noise = 1e6 ;
    if (Gt <= mx_ind_neural_models)
        disp("gaussian, doing amp/phase (neural)")
        sigma = [noise noise] ;
        alpha = noise ;
        options.sources(1).type = 0; % gaussian
    else
        disp("bernouilli, looking at choice")
        sigma = noise ;
        alpha = noise ;
        options.sources(1).type = 1 ; % bernouilli
    end
    options.sources(2).out  = 2;
    options.sources(2).type = 0;  % second output is RT, a gaussian (and in the case of looking at phase that can also be gaussian?)

    options.inG.PhiOpt = 0;


    [y,x, x0, eta, e, u] = VBA_simulate(nt,fname,gname,Ptheta,Pphi,U,alpha,sigma,options,Sx0);

    Y{k} = zeros(2, nt); % I added this isra

    Y{k}(1,:) = y(1,:);
    Y{k}(2,:) = y(2,:);


    SimulParams(k).theta = Ptheta;
    SimulParams(k).x0 = x0;
    SimulParams(k).phi   = Pphi;
    SimulParams(k).x = x ;
    disp("size of x Y1")
    tol = 1e-3; % Tolerance for 4 decimal places
    disp(size(x))
    disp("unique x post precisions PP")
    disp(uniquetol(x(2, end-10:end) , tol))
    disp("uniquetol x pred precision PP")
    disp(uniquetol(x(5, end-10:end) , tol ))
    SimulParams(k).alpha   = alpha;
    SimulParams(k).sigma = sigma ;

    % displaySimulations(y,x,eta,e);

    % this will be written over and only be for last subject if not careful
    % disp("options is : ")
    % disp(options)
    % invert_data(Y, u, SimulParam, options, Mtype, gname, Pobs) ;
end

end

function [gname, phi, Pobs, mx_ind_neural_models] = set_obs_model(Gt)

%Sobs = 0.01*diag(ones(1,length(Pobs)));
alpha_amp_starting = 1.13 ; % perhaps 1.13 μV at rest and 0.43 concentration?
Gtype = ['G' num2str(Gt)];
Pobs = {[alpha_amp_starting, 0]'; [alpha_amp_starting, 1,  0]' ; [alpha_amp_starting, 0 , 1]' ; [alpha_amp_starting , -0.05, 0 , 0.005]' ; [alpha_amp_starting, 10, 0.1, 1, 0]'; [alpha_amp_starting, 10, 0.1, 1, 0]'; [alpha_amp_starting; 10; 0.1; 1; 0]' }; % first 4 for the neural models, last was the default choice one
mx_ind_neural_models = 4 ;
% later to do have different flag for neural or choice obs functions
switch Gtype
    case 'G0' % null model
        disp("Null model") ;
        Pobs{Gt+1,1} = [alpha_amp_starting; 0] ; % Observation parameters (A0, phi0), default was [5 0] , moderate alpha baseline amplitude and phase alignment with trough
        gname = @observation.neural.g_null ;
    case 'G1'
        disp("Amp modified") ;
        Pobs{Gt+1,1}= [alpha_amp_starting; 0.75;  0]; % [A0; A1; phi0; ] % a1 is amp precision weight , start with 1 assuming a moderate positive effect of precision on amplitude (increased precision increases amp)
        gname = @observation.neural.g_amp_precision ;
    case 'G2'
        disp("Phase modified") ;
        Pobs{Gt+1,1} = [alpha_amp_starting; 0 ;1] ; % [A0; phi0; phi1] % phi1 is phase precision weight, positive delays phase (shifts toward trough) , start with 1 , rad vs degrees vs pi ?
        gname = @observation.neural.g_phase_precision ;
    case 'G3'
        disp("amp and phase modified by PE") ;
        Pobs{Gt+1,1} = [alpha_amp_starting; 0.05; 0 ;0.005]; %  [A0; A1; phi0; phi1] % amp decreases as error increases, since pe should be in ms a1 should be small as well
        gname = @observation.neural.g_amp_phase_pe ; % phi1 is the phase pe weight, pos means phase increases (advances) when the isi is longer than expected
    case 'G4'
        disp("kuramoto hopf amp phase") ;
        Pobs{Gt+1,1} = [alpha_amp_starting; 0.05; 0 ;0.005]; %  [A0; A1; phi0; phi1] , though here they're not useds
        gname = @observation.neural.g_kuramoto ;
    case 'G5'
        disp("bay ddm choice model") ; % currently not working
        % previous Response model for choice and reaction time
        Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
        gname = @observation.choice.g_bay_ddm;
    case 'G6'
        disp("sdt choice model") ;
        % previous Response model for choice and reaction time
        Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
        gname = @observation.choice.g_signal_detection;

    otherwise
        disp("default choice model") ;
        % previous Response model for choice and reaction time
        Pobs{Gt+1,1} = [5; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
        gname = @observation.choice.g_Audio_Resp;


end

phi    = (cell2mat(Pobs(Gt+1)));  %SigmaPhi   = Sobs;
end

function [] = play_sound(U)

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

    Us(int32(Is(i)):int32(Is(i))+Step*StimDur) = StimInt;
end
T    = 1/Fs;
t    = 0:T:Lseq;
t(1) = [];
snd  = 0.2*cos(2*pi*440*t);
Uz   = smooth(Us.*snd);
sound(Uz,Fs);
end




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
