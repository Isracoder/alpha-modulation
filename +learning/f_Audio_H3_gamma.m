
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

    % Use dynamic pX instead of fixed parameter
    pX = current_pX;  % replaces exp(theta_params(2))
    isi = u_input(3) ;
    PE = isi - mu_prior;           % deviation from expectation

    previous_ratio = (prec_prior * pX) / (prec_prior + pX);   % harmonic mean of precisions % ratio here is pt|t-1, previous prior weighted by how much you can trust that
    prec = pU + previous_ratio;                         % base posterior precision (if no error modulation) % pt = pt|t-1 + pU , new prior is previous and sensory observations
    tau = pU / prec;                           % learning rate
    mu = mu_prior + tau * PE;
    % new posterior mean
    ppred = (pU*prec) / (pU + prec); % (1/pU + 1/ratio)^-1
    ppred = (pX*ppred) / (pX + ppred);

    % ppred = 1/prec + 1/pX + 1/pU ;

    if (x_states(6) <= 2.5)
        % fprintf('\nratio=%d: prec=%.3f, tau=%.3f, isi=%.3f, mu_prior=%.3f, new_mu=%.3f, ppred=%.2f, pU=%.2f , pX=%.2f ,  ppred=%.2f\n', ...
        %     ratio, prec, tau,isi, mu_prior, mu, ppred , pU, pX, ppred);
    end

    % Store updated parameters
    fx(1) = mu;
    % fx(2) = log(ppred);  % posterior precision
    fx(2) = log(prec);  % this or above ?
    fx(5) = log(ppred);  % predictive precision
    fx(6) = x_states(6) + isi/1000;

    % Update pX based on prediction error
    % scaled_error = pred_error^2 * ratio;


    % ----- Inverse‑gamma update for pX -----
    % Known variance components in prediction error
    % Prior mean variance = 1/prec_prior
    % Observation noise variance = 1/pU
    % So known part: var_known = 1/pU + 1/prec_prior
    % var_known = 1/pU + 1/ratio ;
    % var_known = 1/pU + 1/prec_prior ;
    var_known = 1/prec + 1/previous_ratio ;


    % Estimate of transition variance from this trial
    % (truncated at zero)
    % delta = max(eps, (PE^2) - var_known); % transition variance
    % target = 1/ delta ;

    delta = log((PE + eps))^2 + var_known ; % relies on pe, difference between my expectation and actual
    % delta = log(delta + eps) ;
    mu_diff = mu - mu_prior ; % difference between my previous expectation and this one
    % delta = log(((mu_diff + eps))^2 - var_known) ;



    % Parameters
    alpha_lambda = 0.95;      % forgetting factor (close to 1 = long memory)
    beta_lambda = 0.85;
    eta = 0.5;         % learning rate (can be merged into lambda)
    alpha_initial = 2;
    beta_initial = 0.5  ;

    % Update with forgetting so that I can recover after initial shocks and decrease in pX
    % alpha_new = alpha_lambda * alpha_pX + (1-alpha_lambda) * (alpha_initial + 0.5 * eta);
    alpha_new = alpha_pX * alpha_lambda + 0.5 ;

    % beta_new  = lambda * beta_pX  + (1-lambda) * (beta_initial + 0.5 * delta * eta);
    % beta_new  = beta_lambda * beta_pX + (1-beta_lambda) * (beta_initial +  (0.5 * abs(delta))) ; % what I had before, with 0.25 lambda
    beta_new  = beta_lambda * beta_pX + (beta_initial +  (0.5 * abs(delta))) ;

    % ALTERNATIVE
    alpha_lambda = 0.95;      % forgetting factor for shape (alpha) , 0.95, 0.5
    beta_lambda  = 0.35;      % forgetting factor for rate  (beta)
    target_alpha = 2;         % steady-state shape of the Gamma distribution

    % Estimate current transition variance from prediction error
    var_known = 1/previous_ratio + 1/prec;              % known variance (state + obs)
    % raw_trans_var = max(0.005, log(PE^2) + var_known);  % avoid zero/negative
    raw_trans_var = max(0.005, sqrt((PE) ^ 2) + var_known);  % avoid zero/negative
    % raw_trans_var = min(raw_trans_var , 4) ;
    % raw_trans_var = max(0.005, log10(mu_diff^2) + var_known);  % avoid zero/negative

    alpha_new = alpha_lambda * alpha_pX + 0.5 ;
    beta_new  = beta_lambda * beta_pX + (1-beta_lambda) * ( 0.5 * raw_trans_var) ;

    if (fx(6) <= 2.0 || (fx(6) >= 30.5 && fx(6) <= 32))
        % fprintf('\nt=%d: e=%.3f, var_known=%.3f, delta=%.3f, a=%.2f, b=%.2f, pX=%.3f, mu=%.3f \n', ...
        %     fx(6), PE, var_known, delta, alpha_new, beta_new, pX , mu);
        fprintf('\nt=%d: e=%.3f, var_known=%.3f, delta=%.3f, previous mu = %.3f , next_mu = %.3f, isi= %.3f, pX=%.3f, a=%.3f, b=%.3f \n', ...
            fx(6), PE, var_known, delta, mu_prior, mu, isi,  pX, alpha_new, beta_new );
    end

    fx(7) = log(alpha_new);  % store in log space
    fx(8) = log(beta_new);

end
