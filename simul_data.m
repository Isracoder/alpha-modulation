function [Y1,U,SimulParam2, Mtype, Gtype] = simul_data(Ns, Mt, Gt,  flag, difficulty, isAuditory)


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
        Mt = 1; Gt = 3;  flag = 0;
        difficulty = 0 ;
        isAuditory = true ;
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
    fprintf('\nDifficulty level: %d , std tone: %d, and deviant: %d \n' , difficulty, std_tone, dev_tone) ;


    % GENERATE INPUT
    if (isAuditory)

        % currently  using the auditory paradigm from morillon, can later on change params and data paradigm
        [U_Predictable] = generate_input(true, 1, 1) ;
        [U_Unpredictable] = generate_input(true, 0, 1) ;

        [U_alternating] = generate_input(true, 0.3 , 1) ;
        [U_aperiodic] = generate_input(true, 0.7, 1) ;


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

        [gname , phi, Pobs, plotNeural, plotChoice, sources, neuralInd] = set_obs_model(Gt, std_tone, dev_tone) ;

        %% Data simulation
        rng('shuffle');

        % % run same two simulations but only difference between P vs UP is input data
        [Y1 , SimulParam1] = simulate(U_Predictable, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;
        [Y2 , SimulParam2] = simulate(U_Unpredictable, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;

        % for adding the different spectral case
        % Pobs_modified = Pobs ;
        % Pobs_modified{Gt+1,1} = [1.13; 10; 0.1; 50; 0; std_tone; dev_tone ; false];
        % phi_modified = (cell2mat(Pobs_modified(Gt+1)));
        % [Y3 , SimulParam1] = simulate(U_Predictable, Ns, Pobs_modified, theta, phi_modified, x0,  Gt, Mt, fname, gname, sources) ; % auditory spectral difference
        % [Y4 , SimulParam2] = simulate(U_Unpredictable, Ns, Pobs_modified, theta, phi_modified, x0,  Gt, Mt, fname, gname, sources) ;

        % cases = struct('U', {U_Predictable, U_Unpredictable, U_Predictable, U_Unpredictable}, ...
        %     'Y', {Y1, Y2, Y3, Y4}, ...
        %     'title', {'PP-S+', 'UP-S+' , 'PP-S-' , 'UP-S-'}, ...
        %     'ind', neuralInd);


        [Y3 , SimulParam1] = simulate(U_alternating, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;
        [Y4 , SimulParam2] = simulate(U_aperiodic, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;
        cases = struct('U', {U_Predictable, U_Unpredictable, U_alternating, U_aperiodic}, ...
            'Y', {Y1, Y2, Y3, Y4}, ...
            'title', {'PP-S+', 'UP-S+' , 'AL-S+' , 'AP-S+'}, ...
            'ind', neuralInd);


        % %% Plotting
        calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2, isAuditory, difficulty) ;

        if (plotNeural && plotChoice)

            calculate_plot_neural(Ns, Mtype, Gt, cases, neuralInd, isAuditory, difficulty) ;
            calculate_plot_choices(Ns, Mtype, Gt, cases, isAuditory, difficulty) ;
        elseif (plotNeural)
            calculate_plot_neural(Ns, Mtype, Gt, cases, neuralInd, isAuditory, difficulty) ;
        elseif (plotChoice)
            calculate_plot_choices(Ns, Mtype, Gt, cases, isAuditory, difficulty) ;
        else
            fprintf("No additional plotting..") ;
        end


    else
        % Visual 4-square conditions
        U_Tp_Sp = generate_input(false, true, 3, true);
        U_Tp_Su = generate_input(false, true, 3, false);

        U_Tu_Sp = generate_input(false, false, 3, true);
        U_Tu_Su = generate_input(false, false, 3, false);

        disp("Before normalizing")
        disp(U_Tu_Su(1:3, 1:10))
        disp(U_Tu_Sp(1:3, 1:10))

        % to ensure temporal input is exactly the same across PP_su and PP_sp reassign temporal part, and same for UP
        U_Tp_Su(1:3, :) = U_Tp_Sp(1:3, :) ; % this way the only thing that differs is the last row relating to the spatial location
        U_Tu_Su(1:3, :) = U_Tu_Sp(1:3, :) ;

        disp("after normalizing")
        disp(U_Tu_Su(1:3, 1:10))
        disp(U_Tu_Sp(1:3, 1:10))

        %% Model definitions

        [fname, x0 , X , theta, Mtype] = set_learning_model(Mt , false) ; % is not auditory

        [gname , phi, Pobs, plotNeural, plotChoice, sources, neuralInd] = set_obs_model(Gt, std_tone, dev_tone, isAuditory) ;

        %% Data simulation
        rng('shuffle');

        % % run same two simulations but only difference between P vs UP is input data
        [Y1 , SimulParam1] = simulate(U_Tp_Sp, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;
        [Y2 , SimulParam2] = simulate(U_Tp_Su, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;

        [Y3 , SimulParam3] = simulate(U_Tu_Sp, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;
        [Y4 , SimulParam4] = simulate(U_Tu_Su, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources) ;
        disp("Simulations finished...")

        cases = struct('U', {U_Tp_Sp, U_Tp_Su, U_Tu_Sp, U_Tu_Su}, ...
            'Y', {Y1, Y2, Y3, Y4}, ...
            'title', {'PP-S+', 'PP-S-' , 'UP-S+' , 'UP-S-'}, ...
            'ind', neuralInd);


        % %% Plotting ,  % will compare across temporal precisions and spatial precisions

        % calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2, isAuditory) ; % first case across similar predictable time, but different spatial precision
        % calculate_plot_precision(Ns, Mtype, SimulParam3 , SimulParam4, isAuditory) ; % second is similar unpredictable timing, and different spatial
        calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam4, isAuditory) ; % this is predictable time/spatial vs unpredictable time/spatial


        if (plotNeural && plotChoice)
            calculate_plot_neural(Ns, Mtype, Gt, cases, neuralInd, isAuditory) ;
            calculate_plot_choices(Ns, Mtype, Gt, cases, isAuditory) ;
        elseif (plotNeural)
            calculate_plot_neural(Ns, Mtype, Gt, cases, neuralInd, isAuditory) ;
        elseif (plotChoice)
            calculate_plot_choices(Ns, Mtype, Gt, cases, isAuditory) ;
        else
            fprintf("No additional plotting..") ;
        end

    end





end







%% Helper functions (subfunctions)

function [Y, SimulParams] = simulate(U, Ns, Pobs, theta, phi, x0,  Gt, Mt, fname, gname, sources)
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
            % fprintf('source number s :%d has value %d and is of type %d' , s , s, sources(s)) ;
            options.sources(s).out = s ;
            options.sources(s).type = sources(s) ; % type 0 is gaussian, 1 is bernouilli, 2 is multinomial
        end
        noise = 1e6 ; % or can set Inf
        alpha = noise ;
        sigma = noise * ones(1, sum(sources == 0)) ; % where sources == 0 let it be noise, should be of length number of gaussian sources
        options.n_sources = length(sources) ;
        fprintf('Number of sources is: %d and gaussians is : %d \n' , options.n_sources , length(sigma)) ;

        options.inG.PhiOpt = 0;


        % simulate the data
        [y,x, x0, eta, e, u] = VBA_simulate(nt,fname,gname,Ptheta,Pphi,U,alpha,sigma,options,Sx0);

        % setting the number/values of observed output dynamically
        rows = size(y, 1) ;
        Y{k} = zeros(rows, nt);
        for j=1:rows
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

function [fname, x0 , X , theta, Mtype] = set_learning_model(Mt, isAuditory)

    % using log since it'll later be exp transformed as precision should be positive
    pU = log(16);      % sensory precision on time, how much weight to give to current incoming sensory data
    pX = log(8);       % prior precision, how `` `` to give to learned expectations, higher priors means slower updating/changing of beliefs
    mu = 450 ;         % prior mean isi, currently set as so, as alternative can draw it from distribution
    pU_s = log(16);      % sensory precision on spatial location

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
            theta  = [pU ; pX;];
        case 'M5' % gamma based + vision
            fname  = @learning.f_Visual_gamma;
            alpha = log(2) ;
            beta = log(0.25) ;
            alpha_s = alpha; beta_s = beta ; % for now same
            X2 = [0 ; log(16) ; alpha_s ; beta_s] ; % for spatial precision, have mean, precision, alpha, beta
            x0     = [X; alpha; beta; X2] ; % mu_s starts with assumption of 0 (center) , prec val initially log(8)
            theta  = [pU ; pU_s;]; % sensory precision for time, and for spatial location
        otherwise
            error("unsupported")

    end

end

function [gname, phi, Pobs, plotNeural, plotChoice, sources, neuralInd] = set_obs_model(Gt, std_tone, dev_tone , isAuditory)

    %Sobs = 0.01*diag(ones(1,length(Pobs)));
    alpha_amp_starting = 1.13 ; % perhaps 1.13 μV at rest and 0.43 during concentration?
    Gtype = ['G' num2str(Gt)];
    Pobs = {[alpha_amp_starting, 0]'; [alpha_amp_starting]'; [alpha_amp_starting; 10; 0.1; 50; 0; std_tone; dev_tone];  [5; 10; 0.1; 1; 0];   [alpha_amp_starting; 10; 0.1; 50; 0; std_tone; dev_tone]; }; % first 4 for the neural models, last was the default choice one


    switch Gtype
        case 'G0' % null model
            disp("Null model") ; % for looking at null observations
            Pobs{Gt+1,1} = [alpha_amp_starting; 0] ; % Observation parameters (A0, phi0), default was [5 0] , moderate alpha baseline amplitude and phase alignment with trough
            gname = @observation.neural.g_null ;
            plotNeural = true ;
            plotChoice = false ;
            neuralInd = 1 ; % index of amplitude in observables
            sources = [0 0] ; % amp phase as is no change
        case 'G1'
            disp("single kuramoto hopf amp phase") ;
            Pobs{Gt+1,1} = [alpha_amp_starting; ];
            gname = @observation.neural.g_kuramoto_single ;
            plotNeural = true ;
            plotChoice = false ;
            neuralInd = 1 ;
            sources = [0 0 0 0] ; % amp, phase, x coord, y coord

        case 'G2'
            disp("sdt choice model") ;
            Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 50; 0; std_tone; dev_tone ; true]; % Observation parameters (A0, f, sig, gam, t0, k dprime ), default was [5 10 0.1 1 0]';
            % last item in pobs is sameSpectral (true/false)
            gname = @observation.choice.g_signal_detection;
            plotNeural = true ;
            plotChoice = true ;
            neuralInd = 3 ;
            sources = [1 0 0 0 0 0] ; % choice, rt, amp scaling factor, phase, d prime, full amp

        case 'G3'
            disp("default choice model") ;
            % previous Response model for choice and reaction time
            Pobs{Gt+1,1} = [5; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
            gname = @observation.choice.g_Audio_Resp;
            plotChoice = true ;
            plotNeural = true ;
            neuralInd = 3 ;
            sources = [1 0 0 0] ; % choice, rt, amp, phase, bernouilli for choice then all gaussians
        case 'G4'
            if (isAuditory); error("unsupported for this modality!") ; end
            disp("Visual SDT model") ;
            % Pobs{Gt+1,1} = [5; 10; 0.1; 1; 0]; % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
            Pobs{Gt+1,1} = [1.13; 10; 0.1; 50; 0; 440; 880; true; 0.5; 0.5; 0.5; 0.5];
            gname = @observation.choice.g_visual;
            plotNeural = true ; % should add separate considerations in neural plotting if I want to display both hemispheres
            plotChoice = true;
            neuralInd = [3,4];  % indices for left and right alpha amplitudes
            sources = [1 0 0 0 0 0];  % choice, RT, left_amp, right_amp, left_phase, right_phase, dprime


        case 'G5'  % SDT style with extended energy based
            disp("Energy model") ;
            if (Mt ~= 5); error ("Incorrect F Function!") ; end
            % previous Response model for choice and reaction time
            Pobs{Gt+1,1} = [alpha_amp_starting; 10; 0.1; 50; 0; std_tone; dev_tone];% Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
            gname = @observation.choice.g_energy;
            plotChoice = true ;
            plotNeural = true ;
            neuralInd = 3 ;
            sources = [1 0 0 0 0] ; % choice, rt, amp, phase, d prime


        otherwise
            error('Unsupported model type!')

    end

    phi = (cell2mat(Pobs(Gt+1)));
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


