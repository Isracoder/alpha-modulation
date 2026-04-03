function [gx] = g_kuramoto(x_states,phi_params,u_input,inG)

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
[amp , phase] = neural_mm.hopf_oscillator(precision) ;

gx(1) =  max(amp) ;
gx(2) = max(phase) ;
% check if x2 here is precision or variance which would give inverse

% how to add choice and rt based on this model? or should I link to other one
