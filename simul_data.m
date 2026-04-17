function [Y1,U,SimulParam2, Mtype, Gtype] = simul_data(Ns,Im, Mt, Gt,  flag, difficulty)


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
    arguments
        Ns = 1; Im = 1; Mt = 1; Gt = 7;  flag = 0;
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
    % later on pass difficulty/tone values if needed
    [U_Predictable, ISIm_pred] = generate_input(true, true, 1) ; % currently have this be auditory and predictable, later more dynamic with Im being passed in to influence predictability
    [U_Unpredictable, ISIm_unpred] = generate_input(true, false, 1) ;
    % [U_B] = generate_input(true, false, 2, false) ; % t unpredictable ,s unpredictable, for paradigm B

    % Sound play (over 20 seconds)
    if flag
        play_sound(U_Predictable) ;
    end

    %% Model definitions

    % using log since it'll later be exp transformed as precision should be positive
    pU = log(16);      % sensory precision, how much weight to give to current incoming sensory data, higher precision is more reliability and less variance
    pX = log(8);       % prior precision, how `` `` to give to learned expectations, higher priors means slower updating/changing of beliefs
    mu = 450 ;         % prior mean isi, can have it be based on distribution or not
    % % mu = log(ISIm_pred ) + sqrt(0.3)*randn(1,1);         % prior mean ISI  % was ISIm changed to random from distributions, this also induces high accuracy
    % % variance added

    % % my assumption [previous posterior mean, previous posterior precision, previous prior mean, previous prior precision, predictive precision , time] , it could be that the predictive precision is the same as the posterior assuming an optimal bayesian learner
    X  = [mu log(16) mu log(16) log(16) 0]';
    %SX = 0.01*diag(ones(1,length(X)));

    % Reasonable initial values:
    initial_pi1    = 1/100^2;      % precision = 1/variance (variance ~ 100 ms^2)
    initial_mu1    = 500;          % e.g., mean ISI in ms
    initial_pred_prec = initial_pi1;  % same


    % X = [initial_mu1, log(initial_pi1), initial_mu1, log(initial_pi1), ...
    %     log(initial_pred_prec), 0]';


    Mtype = ['M' num2str(Mt)]; % I changed this to use an additional Mt flag to uncouple from Im, seems to have no effect on success rate even with periodic sequence (0 Im) and adaptative model (1 Mt)
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

        case 'M2' % My Adaptive model, can assume shifting gaussian
            fname  = @learning.f_Audio_modified;
            x0     = X;            %SigmaX0    = SX;
            theta  = [pU ; pX];    %SigmaTheta = diag([0.05 0.001]);
        case 'M3' % currently don't use and have other
            fname  = @learning.f_Audio_H2_HGF;
            initial_mu2    = log(5);      % assume moderate volatility (e.g., 0.1 log precision)
            initial_pi2    = log(1);             % low precision for initial uncertainty
            x0     = [X; initial_mu2; initial_pi2] ;
            theta  = [pU ; pX; 0.5; log(2); log(0.1)];
            % theta here 5 params [pU; pX; baseline log volatility/omega; coupling/kappa; step size]
            % have them all as log vals except 3rd since omega can be negative
        case 'M4' % My Adaptive model, can assume shifting gaussian
            fname  = @learning.f_Audio_H3_gamma;
            alpha = log(2) ;
            beta = log(0.25) ;
            x0     = [X; alpha; beta] ;     % here added states are alpha and beta in inverse gamma distribution
            theta  = [pU ; pX;];    %SigmaTheta = diag([0.05 0.001]);


        case 'M5' % kuramoto linked, learns cartesian as wel
            fname  = @learning.f_Audio_H4_gamma_oscillator;
            alpha = log(2) ;
            beta = log(0.25) ;
            theta0 = 2*pi*rand(1,1);
            r0 = 1;
            x_initial = r0*cos(theta0);
            y_initial = r0*sin(theta0); % should I use sinpi here or no need ?
            x0     = [X; alpha; beta; x_initial; y_initial] ;     % here added states are alpha and beta in inverse gamma distribution
            theta  = [pU ; pX;];    %SigmaTheta = diag([0.05 0.001]);
        otherwise
            error("unsupported")

    end

    [gname , phi, Pobs, mx_ind_neural_models] = set_obs_model(Gt, std_tone, dev_tone) ;

    %% Data simulation
    rng('shuffle');

    % % run same two simulations but only difference is P vs UP input data
    [Y1 , SimulParam1] = simulate(U_Predictable, Ns, Pobs, theta, phi, x0,  Gt, Mt, mx_ind_neural_models, fname, gname) ;
    [Y2 , SimulParam2] = simulate(U_Unpredictable, Ns, Pobs, theta, phi, x0,  Gt, Mt,  mx_ind_neural_models, fname, gname) ;

    % percentageDevPP = (U_Predictable(2,:) == 1) / (U_Predictable(1,:) == 1) ;
    % percentageDevUP = (U_Unpredictable(2,:) == 1) / (U_Unpredictable(1,:) == 1) ;

    % fprintf('dev percentage PP: %d\n', percentageDevPP); % verified both cases have deviant percentage of 0.5
    % fprintf('dev percentage UP: %d\n', percentageDevUP);

    % %% Plotting
    calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2) ;

    if (Gt <= mx_ind_neural_models)
        calculate_plot_neural(Ns, Mtype, Gt,  U_Predictable, Y1 , U_Unpredictable , Y2) ;
    elseif (Gt == 7) % the default one embedded with both neural and choice now
        calculate_plot_neural(Ns, Mtype, Gt,  U_Predictable, Y1 , U_Unpredictable , Y2) ;
        calculate_plot_choices(Ns, Mtype, Gt, U_Predictable, Y1 , U_Unpredictable , Y2) ;
    else
        calculate_plot_choices(Ns, Mtype, Gt, U_Predictable, Y1 , U_Unpredictable , Y2) ;

    end


end


%% Helper functions (subfunctions)

function [Y, SimulParams] = simulate(U, Ns, Pobs, theta, phi, x0,  Gt, Mt, mx_ind_neural_models, fname, gname)
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
            sigma = [noise noise] ; % needs to be changed upon changing num of gx params/output
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

        % for third output, here may be x
        if (Mt >= 4) % look at mt or gt ?
            % need to do this to carry over amp parameter (third in gx), later do similar settings for phase
            options.sources(3).out = 3 ;
            options.sources(3).type = 0 ; % how to set this up to be a vector of gaussians ?
            sigma = [noise noise noise] ;
            options.n_sources =3  ;
        end
        if (Gt == 7 || Gt == 4)
            options.sources(3).out = 3 ;
            options.sources(3).type = 0 ; % how to set this up to be a vector of gaussians ?

            % the case of [choice rt amp phase] or [amp phase x y] , reorganize this later for more structure
            options.sources(4).out = 4 ;
            options.sources(4).type = 0 ;
            sigma = [noise noise noise noise] ;
            options.n_sources =4  ;
        end

        options.inG.PhiOpt = 0;


        [y,x, x0, eta, e, u] = VBA_simulate(nt,fname,gname,Ptheta,Pphi,U,alpha,sigma,options,Sx0);

        cols = size(y, 1) ;
        Y{k} = zeros(cols, nt); % I added this isra
        disp("num of cols: ")
        disp(cols)
        for j=1:cols
            Y{k}(j,:) = y(j,:);
        end



        SimulParams(k).theta = Ptheta;
        SimulParams(k).x0 = x0;
        SimulParams(k).phi   = Pphi;
        SimulParams(k).x = x ;
        SimulParams(k).alpha   = alpha;
        SimulParams(k).sigma = sigma ;
        % disp("size of x Y1")
        % tol = 1e-3; % Tolerance for 4 decimal places
        % disp(size(x))
        % disp("unique x post precision at end")
        % disp(uniquetol(x(2, end-10:end) , tol))
        % disp("uniquetol x pred precision at end")
        % disp(uniquetol(x(5, end-10:end) , tol ))

        % displaySimulations(y,x,eta,e);

        % this will be written over and only be for last subject if not careful

        % invert_data(Y, u, SimulParam, options, Mtype, gname, Pobs) ;
    end

end

%% Helper function for observation model selection

function [gname, phi, Pobs, mx_ind_neural_models] = set_obs_model(Gt, std_tone, dev_tone)

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
            disp("single kuramoto hopf amp phase") ;
            Pobs{Gt+1,1} = [alpha_amp_starting; 0.05; 0 ;0.005]; %  [A0; A1; phi0; phi1] , though here they're not useds
            gname = @observation.neural.g_kuramoto_single ;

        case 'G5'

            disp("kuramoto hopf amp phase multiple") ;
            Pobs{Gt+1,1} = [alpha_amp_starting; 0.05; 0 ;0.005]; %  [A0; A1; phi0; phi1] , though here they're not useds
            gname = @observation.neural.g_kuramoto_train ;
            % disp("bay ddm choice model") ; % currently not working
            % % previous Response model for choice and reaction time
            % Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
            % gname = @observation.choice.g_bay_ddm;
        case 'G6'
            disp("sdt choice model") ;
            k_dprime = 0.5 ;
            Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 50; 0; k_dprime; std_tone; dev_tone]; % Observation parameters (A0, f, sig, gam, t0, k dprime ), default was [5 10 0.1 1 0]';
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


