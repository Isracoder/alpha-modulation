function [fx] = f_Audio_H1(x_states,theta_params,u_input,~)

% states
% x states are [previous posterior mean, previous posterior precision, previous prior mean, previous prior precision, predictive precision , time] , it could be that the predictive precision is the same as the posterior assuming an optimal bayesian learner
% disp(x); % column vector, e.g values are 516.4, 3.0845, 613.47, 3.0845 , 1.45, 741.39
fx = zeros(size(x_states));

fx(1) = x_states(1);
fx(2) = exp(x_states(2)); % x2, 4, and 5 need exp since they were previously log transformed , assumed 16
fx(3) = x_states(1); % initially fx3 and 4 were x1 and 2 respectively, take posterior as prior
fx(4) = x_states(2); % the prior for this trial is taken from the last posterior

% disp(P) ; % 2.7726, 2.0794 as column vector
% parameters
pU    = exp(theta_params(1)); % sensory or data precision , 16 , same thing here regarding log/exp as precision should be pos
pX    = exp(theta_params(2)); % is this prior precision or not? , 8


% input
isi = u_input(3); % varies across runs, can be 492 for example or 548 due to the aperiodic model
% when using the periodic model the isi is constant

% fprintf('\n mu: %d, isi: %d', , isi);

% output - posterior density

ratio = (fx(2)*pX)/(fx(2)+pX); % seems constant at 5.8564, role weighting the previous posterior precision and prior precision ?
% ratio = (fx(2)*exp(x_states(4)))/(fx(2)+exp(x_states(4)));
% effective prior precision after accounting for volatility ? half of the harmonic mean, also used when calculating time rates (a does something in x time, b in y time, together it takes them this )
% seems to be for weighting the precisions ? one precision, and another, combined this is their effect ? all equations seem to be doing this cumulative weighting

prec = pU + ratio;  % add sensory input precision to ratio of prior / previous posterior
% if env changes we trust the prior less and adapt more quickly to new observations , px may be stability in env
tau  = pU/prec; % our learning rate ? modulated by stability/volatility
mu   = fx(1) + tau*(isi - fx(1)); % softmax ? modulates learning of isi mean, pe is diff between actual isi and previous posterior mean of isi (prior)
% fprintf('mu: %d, isi: %d', mu, isi); % when running model these are different, e.g. mu = 5.9e2 , isi = 5.85 or mu = 7.7e2 isi = 8.3, if learning rate is 1 then should simplify to isi exactly

% try to add this to see if precision changes across modalities
% prec = prec/ (pU * ratio); % as prec was pU + ratio now continue and divide

% output - predictive precision
ppred = (pU*prec)/(pU + prec); % weigh sensory input precision to ratio of prior and previous posterior
ppred = (pX*ppred)/(pX + ppred); % weigh predictive precision from first step with prior precision

fx(1) = mu;
% fx(2) = log(prec);
fx(2) = log(ppred);
fx(5) = log(ppred);
fx(6) = x_states(6)+isi/1000;