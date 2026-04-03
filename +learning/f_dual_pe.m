function [fx] = f_dual_pe(x_states,theta_params,u_input,inF)

% [fx] = f_dual_pe(x,P,u,in)
%
% IN:
%   - x: none
%   - P: the response model parameter vector
%   - u: the current input to the observer
%   - in: further quantities handed to the function
%
% OUT:
%   - fx:  learner
% Dual error channels are pPE and nPE (pos neg prediction error)

sens_prec = exp(theta_params(1)) ; % check this
decay = exp(theta_params(2)) ; % check this, decay rate for error channels

prior_prec = exp(x_states(2)) ;
pe = u(3) - x(1) ; % diff between actual and expected isi value

% update the error channels via leaky integration (x3 and 4 are previous pPe and nPe respectively)
pPE = x(3) * decay + max(pe, 0) ; % at least zero
nPE = x(4) * decay + max(-pe, 0) ; % if I expected a lower value for isi than actual this gives 0 as pe itself positive then -pe,0 gives 0, inverse case is when I thought it would be later than actual then pe itself negative so here -pe is positive and -pe, 0 gives higher than 0

% update mean/precision using the pe
posterior_prec = prior_prec + sens_prec ;
post_mean =  x(1) + (sens_prec /  posterior_prec) * pe ; % kalman gain ? do this or not ?
fx = [post_mean; log(post_prec); pPE; nPE] ; % look into changing this to have same format/num states as x ?
