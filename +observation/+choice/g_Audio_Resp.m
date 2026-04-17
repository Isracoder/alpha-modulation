function [gx] = g_Audio_Resp(x_states,phi_params,u_input,inG)

    gx = zeros(2, 1) ; % the choice and reaction time
    PhiOpt = inG.PhiOpt;  % how to check that phase aligns with stimulus timing ?
    % states
    mu    = x_states(3) ;  %  mean for hidden state of ISI prediction
    % Ppost = exp(x(5));
    % post_prec = exp(x_states(2));  % posterior precision, sigma^2
    pred_prec = exp(x_states(5));  % predictive precision
    Tref  = x_states(6);  % elapsed time
    % fprintf('mu= %.4d Ppost= %.d, Tref= %.4f ()\n', mu, Ppost, Tref); % average vals seem to be 4-7e2, 4, 365-380

    % parameters  --- > initially all had exp, does this need exp ? since not log transformed
    A0  = (phi_params(1)); % amplitude
    f   = (phi_params(2)); % frequency
    sig = (phi_params(3)); % noise / covariance ? % without expp seems that it always drifts deterministically to one side, and bad accuracy
    gam = (phi_params(4)); % decision threshold
    t0  = (phi_params(5)); % initial non-decision time , has time at this time point in seconds

    % input , experiment params
    Uv  = u_input(1);  % whether or not it's a visual trial
    Ua  = u_input(2);  % whether it's an auditory std/dev
    isi = u_input(3);  % the isi

    % entropy of the predictive density
    S = 0.5*log(2*pi*exp(1)/pred_prec);  % entropy of gaussian , is half of log(2pe sigma)

    % phase resetting
    Phi = PhiOpt - 2*pi*f*(Tref+mu); % say 500 elapsed and actual mu is 250, then 750 ,
    phase_term = sinpi(2*pi*f*(Tref+isi)+Phi); % simulate sin wave and modulate by tref/isi/phase term

    % Compute drift rate with stimulus-driven baseline
    % Phase modulates sensitivity (multiplicative effect)
    phase_sensitivity = eps + 0.2 * (1 + phase_term);  % Range: [0, 1] , phase term always seems to be 0, leading this to be 1 since initially 0.5 for both terms

    if Uv

        if Ua == 1  % Deviant
            nu = (A0/S) * (0.0 + phase_sensitivity);  % Range: [1, 2] * A0/S
            % initially had this as a/s * 1 + ps, reason of change was that
            % a/s * phase_term gave 0 which lead to chance accuracy
            % nu = 1 ; % this drives accuracy, having value >= 1 for example gives 100%, while 0.5 already gives 91%
        else  % Standard
            nu = -(A0/S) * (0.0 + 0.2 * phase_sensitivity);  % Asymmetric - standards less affected
            % nu = -1 ;
        end

        % fprintf('(A/S)term= %.4d phase sensitivity= %.d, nu= %.4f ()\n', (A0/S), phase_sensitivity, nu);

        % Reaction time
        dt = 1e-3; % time step , 0.01, tried to increase to 1e-4 to get longer time for reactions which would be more accurate but took too long to compute
        N = 100;   % #Monte-Carlo simulations, default 1000


        % fprintf('Nu: %d , sig: %.2d , gam: %.2d, actual stim=%d \n', nu, sig, gam , Ua);

        choices = zeros(N, 1);
        RTs = zeros(N, 1);

        for i=1:N
            z = 0;
            t = 1;
            while true
                z(t+1) = z(t) + nu*dt + sig*sqrt(dt)*randn;
                t = t + 1;

                if z(t) >= gam
                    choices(i) = 1; % changed choice mapping, since when actual stim is 1 , then nu is positive, drift is upward, crossing upward boundary should map to 1
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


        % p_choice_1 = mean(choices == 1);
        % Analyze the participant's choices
        n_choice_1 = sum(choices == 1);
        p_choice_1 = n_choice_1 / N;


        % % Display results
        % fprintf('Participant results across %d trials:\n', N);
        % % fprintf('Choice 0: %d trials (%.2f%%)\n', n_choice_0, p_choice_0*100);
        % fprintf('Choice 1: %d trials (%.2f%%), actual=%d \n', n_choice_1, p_choice_1*100 , Ua);

        % Store participant's decision output
        gx(1) = (p_choice_1 > 0.5);  % if p1 is higher than 50% then is true and chooses 1, else is false and chooses 0

        % gx(1) = (p_choice_1 > 0.5);  % majority vote
        gx(2) = mean(RTs);  % average RT, verify units and standardize when/for plotting

        gx(3) = (A0/S)  ; % amp is actually power modulated by entropy
        % gx(3) = (A0/S) ;
        % for now amp doesn't give good results , seems only -1,0,1 roughly but not a range
        gx(4) = 2*pi*f*(Tref+isi)+Phi ;
        % fprintf('\namplitude= %.4d\n', gx(3)); % average vals seem to be 4-7e2, 4, 365-380


    elseif Uv == 0
        % case when I don't have to respond
        % gx(1) = -1 ;
        % gx(2) = -1 ;
        gx(1) = 0 ; % currently have these as 0, can later have multinomial so that the 0 makes sense and doesn't overlap with actual valid choice
        gx(2) = 0 ;
        gx(3) = (A0 / S)    ; % amp is actually power modulated by entropy
        gx(4) = 2*pi*f*(Tref+isi)+Phi ;
        % gx(3) = x(3) ; % for now crude assumption that it's the same but this should change
        % gx(4) = x(4) ;
        % changed both of these from -1 to evade p [0,1] problem for bernoulli distribution,
        % then kept it as -1 but added max to change p to 0 in vba


    end

