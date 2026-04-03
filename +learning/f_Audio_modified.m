function [fx] = f_Audio_modified(x_states, theta_params, u_input, ~)
% Evolution function for the adaptive learner (H1).
% States: [posterior mean, posterior precision (log), prior mean, prior precision (log), predictive precision (log), time]
% Inputs:
%   x_states: current state vector (column)
%   theta_params: [log(sensory precision); log(prior precision)] (both positive)
%   u_input: input vector, where u_input(3) is the observed ISI (ms)
% Output:
%   fx: next state vector

fx = zeros(size(x_states));
fx(3) = x_states(1); % initially fx3 and 4 were x1 and 2 respectively, take posterior as prior
fx(4) = x_states(2); % the prior for this trial is taken from the last posterior

% --- Extract parameters ---
pU = exp(theta_params(1));   % sensory precision (fixed)
pX = exp(theta_params(2));   % prior precision (fixed)

% --- Current states (before update) ---
mu_prior = x_states(1);           % prior mean (previous posterior mean)
prec_prior = exp(x_states(2));    % prior precision (previous posterior precision)
% Note: the code originally used x_states(4) as prior precision. We keep that,
% but we will update it correctly later.

% --- Observed ISI ---
isi = u_input(3);

% --- Prediction error ---
delta = isi - mu_prior;           % deviation from expectation

% --- Bayesian mean update (unchanged logic) ---
ratio = (prec_prior * pX) / (prec_prior + pX);   % harmonic mean of precisions
prec_base = pU + ratio;                         % base posterior precision (if no error modulation)
tau = pU / prec_base;                           % learning rate
mu = mu_prior + tau * delta;                    % new posterior mean

% --- DIFFERENCE COMPARED WITH F H1 HERE only,  Precision modulation based on prediction error ---
% Large errors reduce precision (increase uncertainty).
% The modulation factor is 1/(1 + k * delta^2) with k chosen so that typical
% errors in the aperiodic condition reduce precision by about half.
% k = 1e-5 works for ISI in ms (delta^2 up to ~360000 → factor ~0.22). (delta max 600? assuming actual for example is 600 and I assumed 0 through gaussian)
k_mod = 1e-5;   % fixed constant (could be made a parameter if desired)
mod = 1 / (1 + k_mod * delta^2);
prec = prec_base * mod;           % modulated posterior precision , modulation decrease can be max around half and min almost none

% prec = prec_prior - tau * prec_prior ;



% --- Predictive precision (unchanged formula, using the modulated precision) ---
ppred = (pU * prec) / (pU + prec);
ppred = (pX * ppred) / (pX + ppred);

% --- Store the updated states ---
fx(1) = mu;                       % new posterior mean
fx(2) = log(prec);                % new posterior precision (log)
% fx(3) = mu;                       % prior mean for next trial (now = posterior mean)
% fx(4) = log(prec);                % prior precision for next trial (now = posterior precision)
fx(5) = log(ppred);               % predictive precision (log)
fx(6) = x_states(6) + isi/1000;   % cumulative time (seconds)