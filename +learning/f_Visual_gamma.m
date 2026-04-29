

function fx = f_Visual_gamma(x_states, theta, u_input, ~)
    % x(1:8)  -> same as auditory (temporal)
    % x(9)    = mu_s (posterior mean location)
    % x(10)   = log(pi_s) (posterior precision location)
    % x(11)   = log(alpha_s)
    % x(12)   = log(beta_s)
    %
    % theta(1) = log(pU_t)   sensory precision for ISI
    % theta(2) = log(pU_s)   sensory precision for location
    % theta(3:4) unused but can hold pX initial etc.

    fx = zeros(size(x_states));
    fx(3) = x_states(1);                 % prior mean = previous posterior mean
    fx(4) = (x_states(2));                 % prior precision = previous posterior precision


    % Temporal update (same as auditory paradigm )
    mu_prior_t = x_states(1);
    prec_prior_t = exp(x_states(2));
    pU_t = exp(theta(1));
    PE_t = u_input(3) - mu_prior_t;

    alpha_pX = exp(x_states(7));  % shape parameter (log transform for positivity)
    beta_pX  = exp(x_states(8));   % scale parameter
    current_pX = alpha_pX / (beta_pX + eps) ;

    ratio_t = (prec_prior_t * current_pX) / (prec_prior_t + current_pX);
    prec_t = pU_t + ratio_t;
    tau_t = pU_t / prec_t;
    mu =  mu_prior_t + tau_t * PE_t;

    ppred = (pU_t * prec_t) / (pU_t + prec_t) ;
    ppred = (current_pX * ppred )/ (current_pX + ppred) ;

    fx(1) = mu ;
    fx(2) = log(prec_t);
    fx(5) = log(ppred);
    fx(6) = x_states(6) + u_input(3)/1000;

    % Update temporal volatility (inverse-gamma)
    var_known_t = 1/pU_t + 1/prec_prior_t;
    delta_t = max(0, PE_t^2 - var_known_t);
    lambda = 0.25; eta = 0.01;
    alpha_new_t = lambda * exp(x_states(7)) + (1-lambda) * (2 + 0.5*eta);
    beta_new_t  = lambda * exp(x_states(8))  + (1-lambda) * (0.25 + 0.5*delta_t*eta);
    fx(7) = log(alpha_new_t);
    fx(8) = log(beta_new_t);

    % Spatial update (VISION)

    % Input u(4) gives actual location (0,1,2) – we map to continuous [-1,1]

    % assuming screen is 21-22 inches (i.e 50~cm ?), each location may be 15cm apart for example, so scale location
    % screen_scaling = 30 ;
    screen_scaling = 1 ;
    switch u_input(4) % can just have this be -1, 1 when generating data for simplicity
        case 0, actual_x = -1 ;   % left
            % case 1, actual_x = 0;    % center
        case 1, actual_x = 1;    % right
    end
    actual_x = actual_x * screen_scaling ;

    mu_prior_s = x_states(9) * screen_scaling;
    prec_prior_s = exp(x_states(10));
    pU_s = exp(theta(2));
    PE_s = actual_x - mu_prior_s; % need better scaling as here data is multimodal (three different locations) , different from case of gaussian for time

    alpha_pX_s = exp(x_states(11));  % shape parameter (log transform for positivity)
    beta_pX_s  = exp(x_states(12));   % scale parameter
    current_pX_s = alpha_pX_s / (beta_pX_s + eps) ;

    ratio_s = (prec_prior_s * current_pX_s) / (prec_prior_s + current_pX_s);
    prec_s = pU_s + ratio_s;
    tau_s = pU_s / prec_s;
    new_mu = mu_prior_s + tau_s * PE_s; % do I need to make sure this maps to [-1, 0, 1] ?

    ppred1_s = (pU_s*prec_s) / (pU_s + prec_s);

    ppred_s = (current_pX_s*ppred1_s) / (current_pX_s + ppred1_s);
    fx(9) = new_mu ;
    fx(10) = log(ppred_s); % again issue of which to choose


    % if (x_states(6) <= 3.5 || (x_states(6) >= 30 && x_states(6) <= 32.0))
    %     fprintf('\nFor space: ratio=%d: prec=%.3f, tau=%.3f, location=%.3f, mu_prior=%.3f, new_mu=%.3f, ppred1=%.2f, pU=%.2f , pX=%.2f ,  ppred=%.2f, error=%.2f\n', ...
    %         ratio_s, prec_s, tau_s , actual_x, mu_prior_s, new_mu, ppred1_s , pU_s, current_pX_s, ppred_s, PE_s);
    % end

    % Update spatial volatility (inverse-gamma)
    var_known_s = 1/pU_s + 1/prec_prior_s;
    delta_s = max(0, (PE_s * 10)^2 - var_known_s); % 30 for scaling ?
    lambda_s = 0.1 ; eta_s = 0.001 ;
    alpha_new_s = lambda_s * alpha_pX_s + (1-lambda_s) * (2 + 0.5*eta_s); % later can have separate variables (eta, lambda_s) for vision
    beta_new_s  = lambda_s * beta_pX_s  + (1-lambda_s) * (0.25 + 0.5*delta_s*eta_s);
    fx(11) = log(alpha_new_s);
    fx(12) = log(beta_new_s);

    % Prior means for next step (temporal and spatial)
    fx(3) = fx(1);
    fx(4) = fx(2);
end