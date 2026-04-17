function [fx] = f_Audio_H2_HGF(x_states,theta_params,u_input,~)
% x_states:
% 1 = mu1 (posterior mean ISI)
% 2 = log(pi1) (posterior precision ISI)
% 3 = mu1 prior (same as x1)
% 4 = pi1 prior (same as x2)
% 5 = predictive precision (same as x2 in your code)
% 6 = time accumulator
% 7 = mu2 (posterior mean of log volatility) (for pX)
% 8 = log(pi2) (posterior precision of volatility)
fx = zeros(size(x_states));

% --- Level 1: ISI belief (unchanged except pX is dynamic) ---
% fx(1) = x_states(1);                 % posterior mean -> prior mean for next
fx(1) = x_states(1);
fx(2) = exp(x_states(2)); % x2, 4, and 5 need exp since they were previously log transformed , assumed 16
fx(3) = x_states(1);                 % prior mean = previous posterior mean
fx(4) = (x_states(2));                 % prior precision = previous posterior precision

mu_prior = x_states(1);           % prior mean (previous posterior mean)
prec_prior = exp(x_states(2));    % prior precision (previous posterior precision)

% Parameters (all in natural space, but kept positive via exp)
pU    = exp(theta_params(1));        % sensory precision (fixed)
isi = u_input(3) ;
PE = isi - mu_prior;           % deviation from expectation
% omega2 = theta_params(3);            % baseline log volatility (can be negative)
% kappa  = exp(theta_params(4));       % coupling strength (>=0)

% Dynamic pX from level 2 (prior precision for level 1)
% Use previous trial's mu2 (x_states(7))
mu2_prev = exp(x_states(7));
pi2_prev = exp(x_states(8));           % convert from log
% pX = exp( kappa * mu2_prev + omega2 );   % this replaces fixed exp(theta_params(2))
pX = VBA_random('Gaussian' , mu2_prev,  1/(pi2_prev)) ; % sample pX from it's gaussian

% exactly as before, but with pX now a variable
ratio = (prec_prior * pX) / (prec_prior + pX);   % harmonic mean of precisions
prec = pU + ratio;                         % base posterior precision (if no error modulation)
tau = pU / prec;                           % learning rate
mu = mu_prior + tau * PE;                    % new posterior mean
ppred1 = (pU*prec) / (pU + prec);
ppred = (pX*ppred1) / (pX + ppred1);

if (x_states(6) <= 2.5 )
    fprintf('\nratio=%d: prec=%.3f, tau=%.3f, isi=%.3f, mu_pri=%.3f, new_mu=%.3f, ppred1=%.2f, pU=%.2f, pX=%.2f, ppred=%.2f  \n', ...
        ratio, prec, tau,isi, mu_prior, mu, ppred1 , pU, pX, ppred);
end


% Store updated parameters
fx(1) = mu;
fx(2) = log(ppred);  % posterior precision
fx(5) = log(ppred);  % predictive precision
fx(6) = x_states(6) + isi/1000;



% --- Level 2: Volatility belief (HGF update) ---

% Parameters for level 2 evolution
theta2 = exp(theta_params(5));       % step size (evolution variance for volatility)


% Prediction step for level 2 (random walk with step size theta2)
mu2_pred = mu2_prev;
pi2_pred = 1 / (1/pi2_prev + theta2);

% Volatility prediction error (epsilon2)
% Compute the precision weight from level 1 (psi)
% In HGF, psi = pi1_pred / (pi1_pred + pU) but pi1_pred = pX + pi1_post?
% Safer to use the "ratio" you already have:
psi = ratio / (pU + ratio);     % this is the weight between 0 and 1

% Predictive variance at level 1 (prior variance + sensory noise)
% sigma1_pred = 1 / (pX + pU);    % because prior precision pX + sensory precision pU? Actually careful:
% In HGF, the predictive variance is 1/(pX + pU) only if we treat the prior as having precision pX.
% But your model uses a different combination. Let's keep it consistent with your existing ratio:
% Your "prec = pU + ratio", where ratio = (x2*pX)/(x2+pX).
% So the effective total predictive precision is prec. Thus:
sigma1_pred = 1 / prec;         % predictive variance

% Volatility prediction error (Eq. 11 in Mathys 2014, continuous version)
epsilon2 = ( (PE^2 - sigma1_pred) / (1/pU + 1/prec) ) - 1;
% The denominator (1/pU + 1/prec) is the total predictive uncertainty.

% Update level 2 (learning rate proportional to psi/pi2_pred)
learning_rate2 = psi / pi2_pred;
mu2_new = mu2_pred + learning_rate2 * epsilon2;
pi2_new = pi2_pred + psi;       % precision increases by weight

if (x_states(6) <= 2.5 )
    fprintf('\nsigma1_pred=%d: epsilon2=%.3f, psi=%.3f, pi2_pred=%.3f, l2=%.3f, mu2=%.3f, pi2=%.3f  \n', ...
        sigma1_pred, epsilon2, psi, pi2_pred, learning_rate2, mu2_new, pi2_new);
end


fx(7) = log(mu2_new);
fx(8) = log(pi2_new);

end

% % --- Level 2: Volatility belief update (HGF) ---
% % Parameters for level 2 evolution
% theta2 = exp(theta_params(5));       % step size (evolution variance for volatility)

% % Prediction step for level 2
% mu2_pred = mu2_prev;                 % random walk mean stays
% pi2_prev = exp(x_states(8));         % previous precision (exp from log)
% pi2_pred = 1 / (1/pi2_prev + theta2); % precision decreases over time, see if I keep or change this

% % Volatility prediction error (epsilon2)
% % First, compute the "precision weight" from level 1 update
% pi1_post = exp(fx(2));               % posterior precision of ISI
% pi1_pred = pX + pi1_post;            % predictive precision? Actually careful:
% % In HGF, predictive precision at level 1 = pX + posterior precision from previous trial?
% % Better to follow Mathys et al. 2011, 2014.
% % Simplified: use the "ratio" you already computed.
% psi = ratio / (pU + ratio);          % this is the precision weight (0 to 1)


% % Expected uncertainty at level 1
% sigma1_pred = 1 / (pX + pi1_post);   % predictive variance

% % Volatility prediction error
% epsilon2 = ( (delta1^2 - sigma1_pred) / (pU + pi1_post) ) - 1;





