
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
    posterior_prec = pU + previous_ratio;                         % base posterior precision (if no error modulation) % pt = pt|t-1 + pU , new prior is previous and sensory observations
    tau = pU / posterior_prec;                           % learning rate
    mu = mu_prior + tau * PE;
    % new posterior mean
    ppred = (pU*posterior_prec) / (pU + posterior_prec); % (1/pU + 1/ratio)^-1
    ppred = (pX*ppred) / (pX + ppred);


    % Store updated parameters
    fx(1) = mu;
    % fx(2) = log(ppred);  % posterior precision
    fx(2) = log(posterior_prec);  % this or above ?
    fx(5) = log(ppred);  % predictive precision
    fx(6) = x_states(6) + isi/1000;


    % ----- Inverse‑gamma update for pX -----
    % % FROM NEW PAPERS
    alpha_lambda = 1;      % forgetting factor for shape (alpha) , 0.95, 0.5
    beta_lambda  = 0.75;      % forgetting factor for rate  (beta)


    % % Estimate current transition variance from prediction error
    var_known = 1/previous_ratio + 1/posterior_prec;
    % log_PE = log(isi) - log(mu_prior);
    %    mu_diff = mu - mu_prior ;
    transition_val = max(0.005, sqrt((abs(PE) + eps) ^ 2) + var_known);

    alpha_new = alpha_lambda * alpha_pX + 0.5 ;
    beta_new  = beta_lambda * beta_pX +  ( 0.5 * transition_val) ;


    fx(7) = log(alpha_new);  % store in log space
    fx(8) = log(beta_new);

    % current choices are
    % keep a_lam = 1 , b_lam = 0.75 and with (1-beta_lambda)
    % keep a_lam = 1 , b_lam = 0.75 and without (1-beta_lambda)
    % keep a_lam = 1 , b_lam = 0.9 and with (1-beta_lambda)
    % alt in k model
    % previous alternative keep a_lam = 0.95, b = 0.35, and with (1-beta_lambda)
end

% if (fx(6) <= 2.0 || (fx(6) >= 30.5 && fx(6) <= 32))
%     % fprintf('\nt=%d: e=%.3f, var_known=%.3f, delta=%.3f, previous mu = %.3f , next_mu = %.3f, isi= %.3f, pX=%.3f, a=%.3f, b=%.3f \n', ...
%     %     fx(6), PE, var_known, delta, mu_prior, mu, isi,  pX, alpha_new, beta_new );
% end