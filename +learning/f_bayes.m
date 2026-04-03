function [fx] = f_bayes(x_states,theta_params,u_input,inF)

% [fx] = f_bayes(x,P,u,in)
%
% IN:
%   - x: none
%   - P: the response model parameter vector
%   - u: the current input to the observer
%   - in: further quantities handed to the function
%
% OUT:
%   - fx: bayes learner
%
sens_prec = exp(theta_params(1)) ; % check this
prior_prec = exp(x_states(2)) ;
posterior_prec = prior_prec + sens_prec ;
post_mean =  (prior_prec * x(1) + sens_prec * u(3)) / posterior_prec ;
fx = [post_mean; log(post_prec)] ; % look into changing this to have same format/num states as x ?
