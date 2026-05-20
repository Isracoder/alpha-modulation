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
    S_entropy = max(0 , 0.5*log(2*pi*exp(1)/pred_prec));  % entropy of gaussian , is half of log(2pe sigma)

    % phase resetting
    % Phi = PhiOpt - 2*pi*f*(Tref+mu);
    % phase_term = sinpi(2*pi*f*(Tref+isi)+Phi); % simulate sin wave and modulate by tref/isi/phase term , in case of phiopt 0 this simplified to 2pif (isi-mu)
    % phase_term = sinpi(2 * pi * input_delta) ; % [0 , 1]

    T = 1000 / f ; % 100 ms is one period for 10hz (10 per second, 1 per 100ms),
    input_delta = isi - mu ;
    input_delta = input_delta - T * round (input_delta/T) ; % basically modulo but safer

    a_floor = 0.20  ; kappa = -0.5 ;
    a_max = power * exp (kappa * S_entropy) ; % the greater the number in the exponent increases, the more it decreases, i.e greater uncertainty lowers a_max
    % a_max = power/ S_entropy ;

    % in case of arriving at peak (T = 50 or -50), then cos = -1, and amp is max (as arrival was peak)

    % Compute drift rate with stimulus-driven baseline
    % Phase modulates sensitivity (multiplicative effect)
    % phase_sensitivity = 0.5 * (1 + phase_term);  % Range: by 0.5 then [0.5 , 1] , if by 0.2 [0, 0.4]
    phase_term =  ((1 - cos(2* pi* (input_delta) / T)) / 2 )  ; % if peak then 0 , if trough then 1;
    modified_amp =  (a_floor +  (a_max - a_floor) * phase_term);

    if Uv
        estimated_ceiling = 1 ;
        nu = max(0 , estimated_ceiling - modified_amp) ; % basically a lower amp at time t gives higher nu, thus better choice
        if Ua == 0  % in the case of a standard drift toward the bottom
            nu = -nu ;
        end

        if (Tref <= 2.5)
            % Expected accuracy (theoretical)
            expected_accuracy = 1 / (1 + exp(-2*nu*gam/sig^2));
            fprintf('Expected accuracy: %.2f%%, sig:%.2f , gam: %.2f, nu: %.2f%% \n', expected_accuracy*100 , sig , gam, nu);
        end
        % Reaction time
        dt = 0.01; % time step , 0.01, tried to increase to 1e-4 to get longer time for reactions which would be more accurate but took too long to compute
        N = 100;   % #Monte-Carlo simulations, default 1000

        choices = zeros(N, 1);
        RTs = zeros(N, 1);

        for i=1:N
            z = 0;
            t = 1;
            while true
                z(t+1) = z(t) + nu*dt + sig*sqrt(dt)*randn;
                t = t + 1;

                % RTs(i) = t0 + t*dt; % with t0 gives me the time at which I made my choice since (time till now + choice)
                % for actual rt do without it
                RTs(i) = t*dt;

                if z(t) >= gam
                    choices(i) = 1; % flipped choice mapping, since when actual stim is 1 , then nu is positive, drift is upward, crossing upward boundary should map to 1
                    break;
                elseif z(t) <= -gam
                    choices(i) = 0;
                    break;
                end
            end
        end

        % analyze
        p_choice_1 = mean(choices == 1);
        b_outcome = VBA_random ('Bernoulli', p_choice_1);
        if b_outcome == 1; choice = 1; else; choice = 0; end
        gx(1) = choice ;
        % gx(1) = (p_choice_1 > 0.5);  % if majority vote 1 then choose dev, else it's false (standard)
        gx(2) = mean(RTs) + t0;  % average the RTs + non-decision time


    elseif Uv == 0 % no-go trial
        gx(1) = 0 ; % currently have these as 0, can later have multinomial so that the 0 makes sense and doesn't overlap with actual valid choice
        gx(2) = 0 ;
    end
    % gx(3) = (power / S_entropy)    ;
    gx(3) = modified_amp    ;
    % gx(4) = 2*pi*f*(Tref+isi)+Phi ;
    gx(4) = 2 * pi * input_delta ;
end

