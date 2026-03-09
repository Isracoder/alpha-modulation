function [gx] = g_phase_precision(x,P,u,inG)

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

amp = P(1); % take previous amplitude constant
precision = exp(x(2)) ; % should I take x(2) x(4) or x(5) ? the posterior prior or predictive ?

gx(1) = amp;
gx(2) = inG.PhiOpt * precision ; % maybe not correct ? does this always give it optimal or 0 ?