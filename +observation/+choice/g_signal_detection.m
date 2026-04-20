function [gx] = g_signal_detection(x_states,P,u,inG)
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


    gx = zeros(2,1);
    PhiOpt = inG.PhiOpt; % currently passed in as 0

    % States from learning model
    mu    = x_states(1);                % posterior mean of ISI (ms)
    pred_prec = exp(x_states(5));           % predictive precision, use exp as it was log-transformed when stored
    Tref  = x_states(6);  % elapsed time


    % Observation parameters (A0, f, sig, gam, t0), default was [5 10 0.1 1 0]';
    power  = (P(1)); % amplitude
    f   = (P(2)); % frequency
    sig = (P(3)); % noise / covariance ?
    gam = (P(4)); % decision threshold
    t0  = (P(5)); % initial non-decision time ?
    std_tone = P(6); %
    dev_tone = P(7); %

    % Inputs
    Uv = u(1);                   % 1 = visual trial, 0 = non‑visual
    Ua = u(2);                   % 0 = standard, 1 = deviant , in the visual trial case
    isi = u(3);                  % actual ISI on this trial (ms)

    if Uv == 1

        % Entropy of Gaussian predictive density (differential entropy)
        S = 0.5 * log(2*pi*exp(1) / pred_prec); % more precision -> more certainty -> smaller log value and smaller entropy, possibly negative ?

        % % phase resetting
        Phi = PhiOpt - 2*pi*f*(Tref+mu);
        phase_term = sinpi(2*pi*f*(Tref+isi)+Phi);
        phase_sensitivity = 0.2 * (1 + phase_term);

        % Alpha power (proportional to 1/entropy and modulated by phase)
        % Ensure S is not zero; if entropy negative, power becomes negative –
        S = max(S , eps) ; % make sure no neg or 0 ;
        amplitude = (power / S) * phase_sensitivity; % smaller entropy/uncertainty -> more power
        effective_prec =  (pred_prec * amplitude) ; % higher precision and amplitude


        %% FIRST SOLUTION
        mu_standard = log(std_tone) ;
        mu_deviant = log(dev_tone) ;
        sigma_std = sqrt(1/pred_prec);  % higher precision is smaller deviation sigma is standard deviation
        % sigma_std = sqrt(1/effective_prec); % can also have this
        d_prime = (mu_deviant - mu_standard) / sigma_std ;
        criterion = (mu_standard + mu_deviant) / 2 ;  % neutral bias , perfectly in middle, test this mean vs having at 0

        if (Ua == 1); mu = mu_deviant; else; mu = mu_standard ; end

        x = mu + sigma_std * randn(1);  % internal response, draw from the normal distribution of the tone (std or dev)
        if x > criterion ; choice = 1  ;else; choice = 0 ; end % if value of log of tone is higher than criterion(midpoint between two values), this tilts it to deviant, else to


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
        % p_correct = 0.5 * (1 - erf(-x / sqrt(2)) ) ; % these three are equivalent
        % p_correct2 = 0.5 * (1 + erf(x / sqrt(2)));
        % p_correct3 = 0.5 * (erfc(-x / sqrt(2)));
        % % fprintf('mu-standard= %.1d, mu-deviant= %.1d, ,  d_prime=%.3d, criterion=%.2d, actual U= %.1d, response=%.1d, b_outcome=%.1d, entropy = %.2d, post_prec =%.2d ()\n', ...
        % %     mu_standard, mu_deviant , d_prime, criterion,  Ua, choice, b_outcome , S, pred_prec);

        % b_outcome = VBA_random ('Bernoulli', p_correct);
        % if b_outcome == 1; gx(1) = Ua; else; gx(1) = ~Ua; end
        % gx(1) = b_outcome ;
        % % if p_correct > 0.5 % always get p correct which gives 100% accuracy, val in UP case around 0.51, and in PP case ~0.7, even though there is difference both are too accurate
        % %     gx(1) = Ua ;
        % % else
        % %     gx(1) = ~Ua ;
        % % end

        % setting observables

        gx(1) = choice;
        % larger d prime is easier discrimination, smaller/faster reaction time, note that perhaps rt should rely on periodicity not predictability
        RT = t0 + gam / (d_prime + eps);
        gx(2) = RT;
        gx(3) = d_prime;

    else
        % Non‑visual trials – no response expected in this trial
        gx(1) = 0;
        gx(2) = 0;
        gx(3) = 0;
    end
end


