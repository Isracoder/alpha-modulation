function [fx] = f_null(x_states,theta_params,u_input,inF)

% [fx] = f_null(x,P,u,in)
%
% IN:
%   - x: none
%   - P: the response model parameter vector
%   - u: the current input to the observer
%   - in: further quantities handed to the function
%
% OUT:
%   - fx: same states as before no change or learning
%

fx = x_states ;
