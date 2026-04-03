function [gx] = g_amp_phase_pe(x_states,phi_params,u_input,inG)

% [gx] = g_amp_phase_pe(x,P,u,in)
%
% IN:
%   - x: [] states from f function used
%   - P: the response model parameter vector
%   - u: the current input to the observer
%   - in: further quantities handed to the function
%
% OUT:
%   - gx: the predicted output of amplitude and phase
%
% This function computes a model whose amplitude is modulated by precision

gx = zeros(2, 1) ; % amp, phase

amp = phi_params(1); % take previous amplitude constant
weighting = phi_params(2);

pred_err = u_input(3) - x_states(1) ; % difference between actual and predicted isi (previous posterior mean)


gx(1) =  amp - weighting * abs(pred_err); % the more wrong I am the more I decrease the amplitude
gx(2) = phi_params(3) + phi_params(4) * abs(pred_err) ; % the more wrong I am the more I increase phase

% add choice data ? based on what ?


