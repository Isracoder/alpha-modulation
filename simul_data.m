function [Y1,U,SimulParam2, Mtype, Gtype] = simul_data(Ns, Mt, Gt,  flag, difficulty)


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
    % 2026 - Modified by I.Z

    %% Experiment
    arguments
        Ns = 1;
        %  Im = 1;
        Mt = 1; Gt = 7;  flag = 0;
        difficulty = 0 ;
    end
    switch difficulty
        case -1 % very easy case
            std_tone = 440 ;
            dev_tone = 1220 ;
        case 0
            std_tone = 440 ;
            dev_tone = 880 ;
        case 1
            std_tone = 440 ;
            dev_tone = 660 ;
        case 2
            std_tone = 440 ;
            dev_tone = 520 ;
        otherwise
            std_tone = 440 ;
            dev_tone = 880 ;
    end
    disp("std tone: ")

    % GENERATE INPUT

    % currently  using the auditory paradigm from morillon, can later on change params and data paradigm
    [U_Predictable, ISIm_pred] = generate_input(true, true, 1) ;
    [U_Unpredictable, ISIm_unpred] = generate_input(true, false, 1) ;


    % Sound play for first case (over 20 seconds)
    if flag
        play_sound(U_Predictable) ;
    end

    %% Model definitions

    % using log since it'll later be exp transformed as precision should be positive
    pU = log(16);      % sensory precision, how much weight to give to current incoming sensory data
    pX = log(8);       % prior precision, how `` `` to give to learned expectations, higher priors means slower updating/changing of beliefs
    mu = 450 ;         % prior mean isi, currently set as so, as alternative can draw it from distribution


    % % my assumption [previous posterior mean, previous posterior precision, previous prior mean, previous prior precision, predictive precision , time]
    X  = [mu log(16) mu log(16) log(16) 0]';
    %SX = 0.01*diag(ones(1,length(X)));

    Mtype = ['M' num2str(Mt)];
    fprintf('Mtype: %s\n', Mtype);
    switch Mtype
        case 'M0'  % Non adaptive model, assumes fixed gaussian
            fname  = @learning.f_Audio_H0;
            x0     = X;     %SigmaX0    = SX;
            theta  = pU;    %SigmaTheta = 0.05;
        case 'M1' % Adaptive model, can assume shifting gaussian
            fname  = @learning.f_Audio_H1;
            x0     = X;            %SigmaX0    = SX;
            theta  = [pU ; pX];    %SigmaTheta = diag([0.05 0.001]);

        case 'M2' % needs work
            error("Not Implemented")
            % fname  = @learning.f_Audio_H2_HGF;
            % initial_mu2    = log(5);      % assume moderate volatility (e.g., 0.1 log precision)
            % initial_pi2    = log(1);             % low precision for initial uncertainty
            % x0     = [X; initial_mu2; initial_pi2] ;
            % theta  = [pU ; pX; 0.5; log(2); log(0.1)];

        case 'M3' % uses gamma distribution to modulate pX (prior on precision)
            fname  = @learning.f_Audio_H3_gamma;
            alpha = log(2) ;
            beta = log(0.25) ;
            x0     = [X; alpha; beta] ;     % here added states are alpha and beta in gamma distribution
            theta  = [pU ; pX;];    %SigmaTheta = diag([0.05 0.001]);

        case 'M4' % gamma based + kuramoto linked, learns cartesian as wel
            fname  = @learning.f_Audio_H4_gamma_oscillator;
            alpha = log(2) ;
            beta = log(0.25) ;
            theta0 = 2*pi*rand(1,1);
            r0 = 1;
            x_initial = r0*cos(theta0);
            y_initial = r0*sin(theta0);
            x0     = [X; alpha; beta; x_initial; y_initial] ; % in addition stores cartesian progression of x and y
            theta  = [pU ; pX;];    %SigmaTheta = diag([0.05 0.001]);
        otherwise
            error("unsupported")

    end

    [gname , phi, Pobs, plotNeural, plotChoice, sources] = set_obs_model(Gt, std_tone, dev_tone) ;

    %% Data simulation
    rng('shuffle');

    % % run same two simulations but only difference between P vs UP is input data
    [Y1 , SimulParam1] = simulate(U_Predictable, Ns, Pobs, theta, phi, x0,  Gt, Mt, mx_ind_neural_models, fname, gname, sources) ;
    [Y2 , SimulParam2] = simulate(U_Unpredictable, Ns, Pobs, theta, phi, x0,  Gt, Mt,  mx_ind_neural_models, fname, gname, sources) ;


    % %% Plotting
    calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2) ;

    if (plotNeural && plotChoice)
        calculate_plot_neural(Ns, Mtype, Gt,  U_Predictable, Y1 , U_Unpredictable , Y2) ;
        calculate_plot_choices(Ns, Mtype, Gt, U_Predictable, Y1 , U_Unpredictable , Y2) ;
    elseif (plotNeural)
        calculate_plot_neural(Ns, Mtype, Gt,  U_Predictable, Y1 , U_Unpredictable , Y2) ;
    elseif (plotChoice)
        calculate_plot_choices(Ns, Mtype, Gt, U_Predictable, Y1 , U_Unpredictable , Y2) ;
    else
        fprintf("No additional plotting..") ;
    end


end


%% Helper functions (subfunctions)

function [Y, SimulParams] = simulate(U, Ns, Pobs, theta, phi, x0,  Gt, Mt, mx_ind_neural_models, fname, gname, sources)
    Y = cell(1,Ns);
    SimulParams = struct('theta',[],'phi',[], 'x0', [], 'Pobs', Pobs);

    for k = 1:Ns % currently for each subject and then can do for each subject and each model

        disp(['Simulating data for subject ' num2str(k) ' out of ' num2str(Ns) ' subjects']);

        Uk = U;
        nt = length(Uk);
        options.skipf = zeros(1,nt); % initially zeros, no skipping
        options.skipf(1) = 1; % then indicate which to skip, put first and no-go trials
        options.skipf(U(1, :) == 0) = 1; % skip no-go trials


        % more important before inversion to mark these observations as not important
        % options.isYout = zeros(size(y));
        % options.isYout(:, U(1,:) == 0) = 1;


        % alpha = Inf;  % assumes infinite precision and no noise, assumes ground truth in observations, what I observe is exact
        % sigma = Inf;  % assumes inf precision no state noise, model is deterministic in evolution and state transitions


        %     Ptheta = theta + sqrt(diag(SigmaTheta)).*randn(Ntheta,1); % alternatives on theta and phi
        %     Pphi   = phi + sqrt(diag(SigmaPhi)).*randn(Nphi,1);
        Ptheta = theta;
        Pphi   = phi;
        Sx0    = x0;

        % setting the index/location of each observation source and it's corresponding type
        for s = 1:length(sources)
            options.sources(s).out = s ;
            options.sources(s).type = sources(s) ; % type 0 is gaussian, 1 is bernouilli, 2 is multinomial
        end
        noise = 1e6 ; % or can set Inf
        alpha = noise ;
        sigma = noise * ones(1, sum(sources == 0)) ; % where sources == 0 let it be noise, should be of length number of gaussian sources
        options.n_sources = length(sources) ;


        options.inG.PhiOpt = 0;


        % simulate the data
        [y,x, x0, eta, e, u] = VBA_simulate(nt,fname,gname,Ptheta,Pphi,U,alpha,sigma,options,Sx0);

        % setting the number/values of observed output dynamically
        cols = size(y, 1) ;
        Y{k} = zeros(cols, nt);
        for j=1:cols
            Y{k}(j,:) = y(j,:);
        end


        % store simulation for each kth subject
        SimulParams(k).theta = Ptheta;
        SimulParams(k).x0 = x0;
        SimulParams(k).phi   = Pphi;
        SimulParams(k).x = x ;
        SimulParams(k).alpha   = alpha;
        SimulParams(k).sigma = sigma ;
        % displaySimulations(y,x,eta,e);

    end

end

%% Helper function for observation model selection

function [gname, phi, Pobs, plotNeural, plotChoice, sources] = set_obs_model(Gt, std_tone, dev_tone)

    %Sobs = 0.01*diag(ones(1,length(Pobs)));
    alpha_amp_starting = 1.13 ; % perhaps 1.13 μV at rest and 0.43 during concentration?
    Gtype = ['G' num2str(Gt)];
    Pobs = {[alpha_amp_starting, 0]'; [alpha_amp_starting, 1,  0]' ; [alpha_amp_starting, 0 , 1]' ; [alpha_amp_starting , -0.05, 0 , 0.005]' ; [alpha_amp_starting, 10, 0.1, 1, 0]'; [alpha_amp_starting, 10, 0.1, 1, 0]'; [alpha_amp_starting; 10; 0.1; 1; 0]' }; % first 4 for the neural models, last was the default choice one
    sources = [] ;

    switch Gtype
        case 'G0' % null model
            disp("Null model") ; % for looking at null observations
            Pobs{Gt+1,1} = [alpha_amp_starting; 0] ; % Observation parameters (A0, phi0), default was [5 0] , moderate alpha baseline amplitude and phase alignment with trough
            gname = @observation.neural.g_null ;
            sources = [0 0] ; % amp phase as is no change
        case 'G1'
            disp("single kuramoto hopf amp phase") ;
            Pobs{Gt+1,1} = [alpha_amp_starting; 0.05; 0 ;0.005]; %
            gname = @observation.neural.g_kuramoto_single ;
            plotNeural = true ;
            plotChoice = false ;
            sources = [0 0 0 0] ; % amp, phase, x coord, y coord

        case 'G2'
            disp("sdt choice model") ;
            Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 50; 0; std_tone; dev_tone]; % Observation parameters (A0, f, sig, gam, t0, k dprime ), default was [5 10 0.1 1 0]';
            gname = @observation.choice.g_signal_detection;
            plotChoice = true ;
            plotNeural = false ;
            sources = [1 0 0] ; % choice, rt, d prime

        case 'G3'
            disp("default choice model") ;
            % previous Response model for choice and reaction time
            Pobs{Gt+1,1} = [5; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
            gname = @observation.choice.g_Audio_Resp;
            plotChoice = true ;
            sources = [1 0 0 0] ; % bernouilli for choice then all gaussians

        otherwise
            error('Unsupported model type!')

    end

    phi    = (cell2mat(Pobs(Gt+1)));
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


