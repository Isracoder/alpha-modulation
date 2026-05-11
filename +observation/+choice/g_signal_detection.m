function [gx] = g_signal_detection(x_states,phi_params,u_input,inG)
    % observation function for 2AFC with choice probability and RT, as well as d prime
    % based on signal detection theory
    %
    % INPUTS
    %   x    : hidden states [mu; log_prec; ...; post_prec; Tref]
    %          x(1) = mu (posterior mean of ISI)
    %          x(2) = log posterior precision
    %          x(5) = log predictive precision
    %          x(6) = Tref (elapsed time, not used in final phase)
    %   P    : parameters [A0, f, sig, gam, t0, k_dprime]
    %          P(1) = A0       (alpha amplitude)
    %          P(2) = f        (frequency for phase)
    %          P(3) = sig      (unused – kept for compatibility)
    %          P(4) = gam      (RT scaling factor, larger -> slower RT)
    %          P(5) = t0       (non‑decision time, ms)
    %          P(6) = k_dprime (scaling from alpha power to d')
    %   u    : inputs [Uv; Ua; isi]
    %          u(1) = visual trial flag (1 = go, 0 = no-go)
    %          u(2) = actual stimulus (0 = standard, 1 = deviant)
    %          u(3) = actual ISI (ms)
    %   inG  : input structure (currently only .PhiOpt, assumed 0)
    %
    % OUTPUTS
    %   gx(1) : choice during go trials (0/1) either standard or deviant
    %           and 0 during no-go trials
    %   gx(2) : predicted reaction time (ms) on visual trials,
    %           0 on non‑visual trials.
    %   gx(3) : d prime
    %
    %__________________________________________________________________________


    gx = zeros(7, 1);
    PhiOpt = inG.PhiOpt; % currently passed in as 0

    % States from learning model
    mu    = x_states(1);                % posterior mean of ISI (ms)
    pred_prec = exp(x_states(5));           % predictive precision, use exp as it was log-transformed when stored
    posterior_prec = exp(x_states(2));
    Tref  = x_states(6);  % elapsed time


    % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
    power  = (phi_params(1)); % amplitude
    f   = (phi_params(2)); % frequency
    sig = (phi_params(3)); % noise / covariance ?
    gam = (phi_params(4)); % decision threshold
    t0  = (phi_params(5)); % initial non-decision time ?

    std_tone = phi_params(6); %
    dev_tone = phi_params(7); %
    same_spectral = phi_params(8); % adds a component spectral related precision


    % Inputs
    Uv = u_input(1);                   % 1 = visual trial, 0 = non‑visual
    Ua = u_input(2);                   % 0 = standard, 1 = deviant , in the visual trial case
    isi = u_input(3);                  % actual ISI on this trial (ms)

    % Entropy of Gaussian predictive density (differential entropy)
    S_entropy = 0.5 * log(2*pi*exp(1) / pred_prec); % more precision -> more certainty -> smaller log value and smaller entropy, possibly negative ?
    % S = 0.5 * log(2*pi*exp(1) / posterior_prec) ; % switched to try this to get higher d prime, problem is it giving exteremlyyy high values

    % % phase resetting
    Phi = PhiOpt - 2*pi*f*(Tref+mu);
    phase_term = (2*pi*f*(Tref+isi)+Phi);
    phase_sensitivity = 0.2 * (1 + sinpi(phase_term));

    % Alpha power (proportional to 1/entropy and modulated by phase)
    % Ensure S is not zero; if entropy negative, power becomes negative –
    S_entropy = max(S_entropy , eps) ; % make sure no neg or 0 ;
    amplitude = (power / S_entropy) * phase_sensitivity;
    % make sure the phase term plays a role in the accuracy or else in case of implementing attention fatigue -> higher alpha -> this will give more accuracy even though I'm out of sync
    % currently it's precision based, but there should be a difference within precision cases that focuses on alpha value as well, even if I have low precision me being fatigued/not should play a role
    % possibly in the form of a decay mechanism that decays the role of precision on alpha amplitude with time, and then it also decays the role of


    %% Energy EXTENSION -> goal look at amp and see how it decreases/doesn't over time
    % a_t = amplitude ;
    % prev_energy = 2 ;
    % recovery = 1 ; % value of recovery toward full reserve
    % lambdaE = 0.5  ; % how strongly low reserve pushes amp back up
    % c = 0.5 ; % depletion cost of suppression

    % % a_t = power / S ;

    % suppression = max(power - a_t , 0) % cost of suppression, between typical resting amp and the suppressed/ modulated value

    % energy = prev_energy + recovery * ( 1 - prev_energy) - ( c * suppression * suppression) ; % update energy reserves for next step
    % amplitude = a_t + lambdaE * (1 - prev_energy) ; % actual amp value taking in fatigue/energy reserves

    %% asymmetric amplitude
    a_floor = 10  ;
    % a_max = 40 ;
    kappa = -1 ;
    a_max = power * exp (kappa * S_entropy) ;
    T = 100 ; % 100 ms is 10hz period
    input_delta = isi - mu ;
    input_delta = input_delta - T * round (input_delta/T) ; % basically modulo but safer
    % in case of arriving at peak (T = 50 or -50), then cos = -1, and amp is max (as arrival was peak)
    modified_amp = (S_entropy / power) * (a_floor +  (a_max - a_floor) * (1 - cos(2* pi* (input_delta) / T)) / 2 ) ; % should I replace with sin ?
    % modified_amp = (a_floor +  (a_max - a_floor) * (1 - cos(2* pi* (input_delta) / T)) / 2 ) ; % probably should be renamed to cortical gain ? scale with entropy/power so that wave peak with high precision isn't same as wave peak with low precision


    % is there a problem here in assuming that when stimulus starts that point was 0 (trough) and that the oscillations don't speed up or slow down ?



    mu_standard = log(std_tone) ;
    mu_deviant = log(dev_tone) ;
    % sigma_std = sqrt(1/pred_prec);  % higher precision is smaller deviation sigma is standard deviation
    scale_factor = 4 ;
    % sigma_std = sqrt(scale_factor/amplitude); % amplitude value of alpha reflects cortical gain/excitability
    sigma_std = sqrt(modified_amp) / scale_factor ;
    % problem now is that d prime is too small in normal difficulty case, no sig diff between up/pp across accuracy and rt (only small diff)

    d_prime = max(0.1, (mu_deviant - mu_standard) / sigma_std) ; % take max to ensure no negativity


    if Uv == 1

        % effective_prec =  (pred_prec * amplitude) ; % higher precision and amplitude

        if (same_spectral == true) ; spectral_prec = 1 ; else spectral_prec  = 0.5 ; end % start with crude if-else approximation of spectral related precision
        combined_prec = pred_prec * spectral_prec ;  % for 4 square design task

        %% FIRST SOLUTION
        criterion = (mu_standard + mu_deviant) / 2 ;  % neutral bias , perfectly in middle, test this mean vs having at 0

        if (Ua == 1); mu = mu_deviant; else; mu = mu_standard ; end

        x = mu + sigma_std * randn(1);  % internal response, draw from the normal distribution of the tone (std or dev)
        if x > criterion ; choice = 1  ;else; choice = 0 ; end % if value of log of tone is higher than criterion(midpoint between two values), this tilts it to deviant as the deviant is on the right, else toward the standard which is less than the crit value


        %% SECOND SOLUTION
        % p_correct = Φ(d' / √2)  where Φ is normal CDF
        % Use error function: normcdf(x) = 0.5*(1+erf(x/√2)) , is this eqiv to normcdf(x) = 0.5*(1 - erf(-x/√2)) ?
        % https://www.mathworks.com/help/matlab/ref/erf.html#bupqc9m-3
        % Here x = d'/√2  => x/√2 = d'/2
        % p_correct = 0.5 * (1 + erf(d_prime / 2)); %this is for unbiased, for biased might need to add -criterion for x value
        % x = d_prime/ sqrt(2) ;
        % % p_correct = normcdf(x) ; % this needs toolbox
        % p_correct = 0.5 * (1 - erf(-x / sqrt(2)) ) ; % or erfc ?

        % x = d_prime/ sqrt(2) ;
        % p_correct = 0.5 * (1 - erf(-x / sqrt(2)) ) ; % these three are equivalent, assumes unbiased criterion implicitly
        % p_correct2 = 0.5 * (1 + erf(x / sqrt(2)));
        % p_correct3 = 0.5 * (erfc(-x / sqrt(2)));
        p_correct = 0.5 * (1 + erf(d_prime / 2));  % because d'/√2 / √2 = d'/2
        b_outcome = VBA_random ('Bernoulli', p_correct); % if prob of being correct is 0.7, this draws based on that and gives back 1/0 if I am or am not correct

        % if (x_states(6) <= 2.2 || (x_states(6) > 30 && x_states(6) <= 32.1))
        %     fprintf('mu-standard= %.1d, mu-deviant= %.1d, ,  d_prime=%.3d, p_correct=%.2d, actual U= %.1d, response=%.1d, b_outcome=%.1d, entropy = %.2d, post_prec =%.2d ()\n', ...
        %         mu_standard, mu_deviant , d_prime, p_correct,  Ua, choice, b_outcome , S_entropy, pred_prec);
        % end
        if b_outcome == 1; choice = Ua; else; choice = ~Ua; end
        % link to criterion ?
        % choice = b_outcome ;
        % if p_correct > 0.5 % always get p correct which gives 100% accuracy, val in UP case around 0.51, and in PP case ~0.7, even though there is difference both are too accurate
        %     gx(1) = Ua ;
        % else
        %     gx(1) = ~Ua ;
        % end

        % setting observables

        gx(1) = choice;
        % larger d prime is easier discrimination, smaller/faster reaction time, note that perhaps rt should rely on periodicity not predictability
        RT = t0 + gam / (d_prime + pred_prec + eps);
        gx(2) = RT;
        gx(3) = power / S_entropy ; % power scaled by entropy
        gx(4) = phase_term ;
        gx(5) = d_prime;
        gx(6) = amplitude ; % the full gain/cortical excitability
        gx(7)  = modified_amp ;

    else
        % Non‑visual trials – no response expected in this trial
        gx(1) = 0;
        gx(2) = 0;
        gx(3) = power / S_entropy ;
        gx(4) = phase_term ;
        gx(5) = d_prime; % or have it 0
        gx(6) = amplitude ;
        gx(7) = modified_amp ;


    end
end


