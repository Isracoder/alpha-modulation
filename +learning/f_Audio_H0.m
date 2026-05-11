function [fx] = f_Audio_H0(x_states,theta_params,u_input,~)

    % X  = [mu log(16) mu log(16) log(16) 0]'; % States from simul_data
    % x in order possibly: mean posterior isi , log posterior precision, mean
    % predictive isi, log predictive precision, log ? , Tref
    % reference time cumulative

    % do x1 and x3 track same things at different stages ? post vs pre updating
    fx = zeros(size(x_states));
    prior_mu = x_states(1); % take the previous posterior mean
    prior_precision = exp(x_states(2)); % previous posterior precision
    fx(3) = x_states(1); % previous posterior mean as predictive mean
    fx(4) = x_states(2); % the log precision, why do we use exp with one variable and not the other  ?


    % disp(u) ; % 0 0 600 as column vector
    % disp(P) ; % 2.7726

    % parameters
    pU    = exp(theta_params(1)); % sensory precision, how reliable is the observation, 16
    % higher precision gives more trust to data

    % input
    isi = u_input(3);

    % output - posterior density
    posterior_prec = prior_precision + pU; % new posterior precision (prior + sensory or likelihood)
    mu   = isi - (prior_precision/posterior_prec)*(isi - prior_mu);  % adjust my observation by a precision weighting and the difference between my observation and prior mean
    % if pU >>> fx2 then sensory precision dominates prior, trust observation
    % and mu =~ isi , as right-hand term would cancel out basically and fx(1)
    % may also be equal to isi in that case
    % in non adaptive model mu and isi seem equal at 600

    % output - predictive precision
    ppred = (pU*posterior_prec)/(pU + posterior_prec); % how precise is my prediction for next stimulus ? , same equation where I weight two contributions to look at their effect together
    % half of the harmonic mean

    fx(1) = mu;
    fx(2) = log(posterior_prec); % here we're just carrying over fx(2) from previous x(2), assuming fixed
    fx(5) = log(ppred); % here we're updating the predictive posterior
    fx(6) = x_states(6)+isi/1000; % accumulate time across trials, seconds