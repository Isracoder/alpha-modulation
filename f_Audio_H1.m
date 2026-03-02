function [fx] = f_Audio_H1(x,P,u,~)

% states

% disp(x); % column vector, e.g values are 516.4, 3.0845, 613.47, 3.0845 , 1.45, 741.39
fx = zeros(size(x));

fx(1) = x(1);
fx(2) = exp(x(2)); % x2, 4, and 5 need exp since they were previously log transformed , assumed 16
fx(3) = x(1);
fx(4) = x(2); % why not used here though ?

% disp(P) ; % 2.7726, 2.0794 as column vector
% parameters
pU    = exp(P(1)); % sensory precision , 16 , same thing here regarding log/exp as precision should be pos
pX    = exp(P(2)); % prior precision , 8


% input
isi = u(3); % varies across runs, can be 492 for example or 548 due to the aperiodic model
% when using the periodic model the isi is constant

% fprintf('\n mu: %d, isi: %d', , isi);

% output - posterior density

ratio = (fx(2)*pX)/(fx(2)+pX); % seems constant at 5.8564, role? effective prior precision after accounting for volatility ? half of the harmonic mean, also used when calculating time rates (a does something in x time, b in y time, together it takes them this )
% seems to be for weighting the precisions ? one precision, and another, combined this is their effect ? all equations seem to be doing this cumulative weighting

prec = pU + ratio; % if env changes we trust the prior less and adapt more quickly to new observations , px may be stability in env
tau  = pU/prec; % our learning rate ? modulated by stability/volatility
mu   = fx(1) + tau*(isi - fx(1)); % softmax ? modulates learning of isi mean
% fprintf('mu: %d, isi: %d', mu, isi); % when running model these are different, e.g. mu = 5.9e2 , isi = 5.85 or mu = 7.7e2 isi = 8.3, if learning rate is 1 then should simplify to isi exactly

% output - predictive precision
ppred = (pU*prec)/(pU + prec);
ppred = (pX*ppred)/(pX + ppred); % estimating the isi and variability ?

fx(1) = mu;
fx(2) = log(prec);
fx(5) = log(ppred);
fx(6) = x(6)+isi/1000;