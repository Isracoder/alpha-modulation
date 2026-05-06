
function [fx] = f_Audio_H3_gamma(x_states,theta_params,u_input,~)
    % x_states:
    % 1 = mu1 (posterior mean ISI)
    % 2 = log(pi1) (posterior precision ISI)
    % 3 = mu1 prior (same as x1)
    % 4 = pi1 prior (same as x2)
    % 5 = predictive precision (same as x2 in code)
    % 6 = time accumulator
    % 7 = mu2 (posterior mean of log volatility) (for pX)
    % 8 = log(pi2) (posterior precision of volatility)
    fx = zeros(size(x_states));

    % fx(1) = x_states(1);                 % posterior mean -> prior mean for next
    fx(1) = x_states(1);
    fx(2) = exp(x_states(2)); % x2, 4, and 5 need exp since they were previously log transformed , assumed 16
    fx(3) = x_states(1);                 % prior mean = previous posterior mean
    fx(4) = (x_states(2));                 % prior precision = previous posterior precision

    mu_prior = x_states(1);           % prior mean (previous posterior mean)
    prec_prior = exp(x_states(2));    % prior precision (previous posterior precision)
    Tref = x_states(6) ;

    % Parameters (all in natural space, but kept positive via exp)
    pU    = exp(theta_params(1));        % sensory precision (fixed)

    % pX parameters (inverse gamma)
    alpha_pX = exp(x_states(7));  % shape parameter (log transform for positivity)
    beta_pX  = exp(x_states(8));   % scale parameter


    current_pX = alpha_pX / (beta_pX + eps) ;


    % Safety (avoid a<=1)
    if alpha_pX <= 1
        disp("*")
        current_pX = 2;  % fallback
    end
    % current_pX = beta_pX/(alpha_pX - 1);  % expected precision
    % current_pX = exp(beta_pX , alpha_pX) / gamma(alpha_pX) * exp((1/prior_pX), alpha_pX -1) * exp(-beta_pX / (1/prior_pX))
    % fprintf('Current px: %d\n', current_pX);

    % Use dynamic pX instead of fixed parameter
    pX = current_pX;  % replaces exp(theta_params(2))
    isi = u_input(3) ;
    PE = isi - mu_prior;           % deviation from expectation

    ratio = (prec_prior * pX) / (prec_prior + pX);   % harmonic mean of precisions
    prec = pU + ratio;                         % base posterior precision (if no error modulation)
    tau = pU / prec;                           % learning rate
    mu = mu_prior + tau * PE;                    % new posterior mean
    ppred1 = (pU*prec) / (pU + prec);

    ppred = (pX*ppred1) / (pX + ppred1);


    if (Tref <= 2.5)
        % fprintf('\nratio=%d: prec=%.3f, tau=%.3f, isi=%.3f, mu_prior=%.3f, new_mu=%.3f, ppred1=%.2f, pU=%.2f , pX=%.2f ,  ppred=%.2f\n', ...
        %     ratio, prec, tau,isi, mu_prior, mu, ppred1 , pU, pX, ppred);
    end

    % Store updated parameters
    fx(1) = mu;
    % fx(2) = log(ppred);  % posterior precision
    fx(2) = log(prec);  % this or above ?
    fx(5) = log(ppred);  % predictive precision
    fx(6) = Tref + isi/1000;


    %
    var_known = 1/pU + 1/prec_prior ;


    % Estimate of transition variance from this trial
    % (truncated at zero)
    delta = max(0, PE^2 - var_known);
    % Parameters
    lambda = 0.25;      % forgetting factor (close to 1 = long memory)
    eta = 0.01;         % learning rate (can be merged into lambda)
    alpha_initial = 2;
    beta_initial = 0.25 ;

    % Update with forgetting so that I can recover after initial shocks and decrease in pX
    alpha_new = lambda * alpha_pX + (1-lambda) * (alpha_initial + 0.5 * eta);
    % alpha_new = alpha_pX + 1 ;
    beta_new  = lambda * beta_pX  + (1-lambda) * (beta_initial + 0.5 * delta * eta);
    fx(7) = log(alpha_new);  % store in log space
    fx(8) = log(beta_new);

    %% ENERGY component --> goal look at amp and see how it decreases/doesn't over time

    % Entropy of Gaussian predictive density (differential entropy)
    S = 0.5 * log(2*pi*exp(1) / ppred);
    S = max(S , eps) ; % is there a point of clipping this ? to review


    % a_t = amplitude ;


    prev_energy = x_states(9) ; % should be [0, 1] which represents remaining reserve, 0 is depleted

    power = 1.5 ; % fixed
    % for 3 params vals tested include [1 , 0.5, 0.5 ] , [2 , 0.5, 0.8] , []
    recovery = 0.7 ; % fixed value of recovery toward full reserve
    lambdaE = 0.9  ; % fixed , how strongly low reserve pushes amp back up
    c = 0.7 ; % fixed, depletion cost of suppression

    a_t = power / S ; % represents the optimal expected amp scaling factor

    suppression = max(power - a_t , 0) ; % cost of suppression, between typical resting amp and the suppressed/ modulated value

    % 1st
    % next_energy = prev_energy + recovery * ( 1 - prev_energy) - ( c * suppression * suppression) ; % update energy reserves for next step
    % amplitude = a_t + lambdaE * (1 - prev_energy) ; % actual amp value taking in fatigue/energy reserves

    % 2nd
    % next_energy = prev_energy + recovery * (1 - prev_energy)^2 - (c * suppression^2) % alternative squares the recovery factor, slower recovery when fatigued compared to unsquared equation
    % next_energy = prev_energy + recovery * prev_energy * (1 - prev_energy) - c * suppression^2
    % amplitude = a_t + (a_t * (prev_energy + lambdaE * (1 - prev_energy))) ;  % alternative , low energy amp increase
    %  a_t * (prev_energy + lambdaE * (1 - prev_energy))
    % (a_t * prev_energy + lambdaE * (1 - energy_reserve))


    % other ALTernative model, 3rd
    fatigue_rate = 0.5 ;
    next_energy = prev_energy + recovery * (1-prev_energy)  - (c * suppression^2); % faster recovery with higher energy
    precision_effect = ppred * exp(-fatigue_rate* (1-prev_energy)) ; % what is my fatigue rate ?
    amplitude = a_t + a_t * (prev_energy) * (ppred - precision_effect) ; % have a decaying precision effect over time unless energy high?
    % if energy is high then precision effect is it's maximum value, thus no change in what amp was supposed to be,
    % if energy is low, then precision effect may be 0.7 for example of what is supposed to be, then multiplying this by the amp and energy gives an amount to re-add onto the expected amp to drive it up

    % fprintf('Next energy: %.2d , amplitude: %.2d \n', next_energy, amplitude);
    fx(9) = next_energy ;
    fx(10) = amplitude ; % currently as standby for power/s , then try for whole scaling

end
