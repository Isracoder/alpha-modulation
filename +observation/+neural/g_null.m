function [gx] = g_null(x_states,phi_params,u_input,inG)

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

gx = zeros(2, 1) ;
gx(1) = phi_params(1); % amplitude and phase do not change , learning has no effect on observation
gx(2) = phi_params(2); %  return them constant as is


