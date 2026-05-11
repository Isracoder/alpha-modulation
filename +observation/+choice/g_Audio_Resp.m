function [gx] = g_Audio_Resp(x_states,phi_params,u_input,inG)
    % [gx] = g_Audio_Resp(x,P,u,in)
    %
    % IN:
    %   - x: none
    %   - P: the response model parameter vector
    %   - u: the current input to the observer
    %   - in: further quantities handed to the function
    %
    % OUT:
    %   - gx: the predicted output of choice, RT, amplitude and phase
    %
    % This function computes observables using a DDM based solution, drift rate modulated by amplitude and phase term


    gx = zeros(4, 1) ;
    PhiOpt = inG.PhiOpt;
    % states
    mu    = x_states(3) ;  %  mean for hidden state of ISI prediction
    pred_prec = exp(x_states(5));  % predictive precision
    Tref  = x_states(6);  % elapsed time


    % parameters  --- >
    power = (phi_params(1)); % amplitude
    f   = (phi_params(2)); % frequency
    sig = (phi_params(3)); % noise / covariance
    gam = (phi_params(4)); % decision threshold
    t0  = (phi_params(5)); % initial non-decision time , has time at this time point in seconds

    % input , experiment params
    Uv  = u_input(1);  % whether or not it's a visual trial
    Ua  = u_input(2);  % whether it's an auditory std/dev
    isi = u_input(3);  % the isi

    % entropy of the predictive density
    S_entropy = 0.5*log(2*pi*exp(1)/pred_prec);  % entropy of gaussian , is half of log(2pe sigma)

    % phase resetting
    % Phi = PhiOpt - 2*pi*f*(Tref+mu);
    % phase_term = sinpi(2*pi*f*(Tref+isi)+Phi); % simulate sin wave and modulate by tref/isi/phase term , in case of phiopt 0 this simplified to 2pif (isi-mu)

    T = 100 ; % 100 ms is 10hz period
    input_delta = isi - mu ;
    input_delta = input_delta - T * round (input_delta/T) ; % basically modulo but safer
    phase_term = sinpi(2 * pi * input_delta) ; % [0 , 1]

    a_floor = 10  ;
    a_max = power * exp (-5 * S_entropy) ; % the greater the number in the exponent increases, the more it decreases, i.e greater uncertainty lowers a_max
    % in case of arriving at peak (T = 50 or -50), then cos = -1, and amp is max (as arrival was peak)

    % Compute drift rate with stimulus-driven baseline
    % Phase modulates sensitivity (multiplicative effect)
    % phase_sensitivity = 0.5 * (1 + phase_term);  % Range: by 0.5 then [0.5 , 1] , if by 0.2 [0, 0.4]
    phase_term =  ((1 - cos(2* pi* (input_delta) / T)) / 2 )  ; % if peak then 0 , if trough then 1;
    modified_amp =  (a_floor +  (a_max - a_floor) * phase_term);
    % phase_sensitivity = 0.95 * (0.1 + phase_term) ; % to get range of values representing cortical gain based on phase
    % wave_height_effect = 0.5 * (power/(S + eps)) ; % scale this down to between [0.2 , 0.8]
    % wave_height_effect = rescale(power/(S + eps), 0.03, 0.2, 'InputMin', 0.4, 'InputMax', 2.3); % less prec, more uncertainty, smaller wave height, better perceptability ?
    % wave_height_effect = rescale(power/(S + eps), 0.1, 0.75, 'InputMin', 0.4, 'InputMax', 2.3); % less prec, more uncertainty, smaller wave height, better perceptability ?


    if Uv

        % nu = (wave_height_effect * phase_sensitivity) / (wave_height_effect + phase_sensitivity) ;
        % nu = (1- wave_height_effect) * (1 - phase_sensitivity) + (1-wave_height_effect) * (phase_sensitivity); % greater sensitivity is greater drift
        % nu = (wave_height_effect) * (phase_sensitivity); % greater sensitivity is greater drift
        % nu = (0.8 - wave_height_effect) * (1 - phase_sensitivity) +  (phase_sensitivity); % greater sensitivity is greater drift
        nu = modified_amp ;
        if Ua == 1  % Deviant
            % nu = 0.3 ;
            % nu = 1 ; % this drives accuracy, having value >= 1 for example gives 100%, while 0.5 already gives 91%
        else  % Standard
            % nu = -(wave_height_effect) + (0.2 * phase_sensitivity);  % Asymmetric modulation,  standards less affected than deviants by phase

            nu = -nu ;
            % nu = -0.3 ;
            % nu = -1 ;
        end

        if (Tref <= 2.5)
            % fprintf('nu : %.3d, phase_sensitivity: %.3d , wave_height_effect: %.3d \n' , nu , phase_sensitivity, wave_height_effect) ;
            % Expected accuracy (theoretical)
            expected_accuracy = 1 / (1 + exp(-2*nu*gam/sig^2));
            % fprintf('Expected accuracy: %.2f%%, sig:%.2f , gam: %.2f%% \n', expected_accuracy*100 , sig , gam);

            % gam = 2.0  ;
            % sig = 1.0 ;

            % expected_accuracy = 1 / (1 + exp(-2*nu*gam/sig^2));
            % fprintf('Expected accuracy: %.2f%%\n', expected_accuracy*100);
        end
        % Reaction time
        dt = 0.01; % time step , 0.01, tried to increase to 1e-4 to get longer time for reactions which would be more accurate but took too long to compute
        N = 10;   % #Monte-Carlo simulations, default 1000

        choices = zeros(N, 1);
        RTs = zeros(N, 1);

        for i=1:N
            z = 0;
            t = 1;
            while true
                z(t+1) = z(t) + nu*dt + sig*sqrt(dt)*randn;
                t = t + 1;

                if z(t) >= gam
                    choices(i) = 1; % flipped choice mapping, since when actual stim is 1 , then nu is positive, drift is upward, crossing upward boundary should map to 1
                    % RTs(i) = t0 + t*dt;
                    RTs(i) = t*dt;
                    break;
                elseif z(t) <= -gam
                    choices(i) = 0;
                    % RTs(i) = t0 + t*dt; % with t0 gives me the time at which I made my choice since (time till now + choice)
                    % for actual rt do without it
                    RTs(i) = t*dt;
                    break;
                end
            end
        end

        % analyze
        % n_choice_1 = sum(choices == 1);
        % p_choice_1 = n_choice_1 / N;
        p_choice_1 = mean(choices == 1);
        b_outcome = VBA_random ('Bernoulli', p_choice_1);
        if b_outcome == 1; choice = 1; else; choice = 0; end
        gx(1) = choice ;
        % Probabilistic choice
        % gx(1) = (rand > p_choice_1);  % Bernoulli sample


        % gx(1) = (p_choice_1 > 0.5);  % if majority vote 1 then choose dev, else it's false (standard)
        gx(2) = mean(RTs);  % average the RTs
        gx(3) = (power/S_entropy)  ;
        % gx(4) = 2*pi*f*(Tref+isi)+Phi ;
        gx(4) = 2 * pi * input_delta ;

    elseif Uv == 0 % no-go trial
        gx(1) = 0 ; % currently have these as 0, can later have multinomial so that the 0 makes sense and doesn't overlap with actual valid choice
        gx(2) = 0 ;
        gx(3) = (power / S_entropy)    ;
        % gx(4) = 2*pi*f*(Tref+isi)+Phi ;
        gx(4) = 2 * pi * input_delta ;
    end

