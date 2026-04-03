function [gx] = g_phase_precision(x_states,phi_params,u_input,inG)

% [gx] = g_phase_precision(x,P,u,in)
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
% This function computes a model whose phase is modulated by precision

gx = zeros(2, 1) ; % amp, phase

precision = exp(x_states(2)) ; % should I take x(2) x(4) or x(5) ? the posterior prior or predictive ?

gx(1) = phi_params(1); % constant previous amplitude
gx(2) = phi_params(2) + phi_params(3)/precision ; % phase dependent inversely on precision ?