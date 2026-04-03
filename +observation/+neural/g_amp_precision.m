function [gx] = g_amp_precision(x_states,phi_params,u_input,inG)

% [gx] = g_amp_precision(x,P,u,in)
%
% IN:
%   - x: none
%   - P: the response model parameter vector
%   - u: the current input to the observer
%   - in: further quantities handed to the function
%
% OUT:
%   - gx: the predicted output of amplitude and phase
%
% This function computes a model whose amplitude is modulated by precision

gx = zeros(2, 1) ; % amp, phase

precision = exp(x_states(5)) ; % should I take x(2) x(4) or x(5) ? the posterior prior or predictive ?
gx(1) =  phi_params(1) - phi_params(2) / (precision); % here larger precision (i.e more sure) gives larger amplitude, look into setting bounds for this (think  of either + p * p or - p/p)
gx(2) = phi_params(3) ; %constant

% check if x2 here is precision or variance which would give inverse

