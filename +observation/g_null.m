function [gx] = g_null(x,P,u,inG)

% [gx] = g_null(x,P,u,in)
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
% This function computes a null model which produces a constant output
% response, regardless of the input stimulus

gx = zeros(2, 1) ; % amp, phase

amp = P(1); % take previous amplitude constant

gx(1) = amp;
gx(2) = inG.PhiOpt ; % maybe not correct ? does this always give it optimal or 0 ?


