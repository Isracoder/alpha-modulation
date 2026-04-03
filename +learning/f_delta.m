function [fx] = f_delta(x_states,theta_params,u_input,inF)

% [fx] = f_delta(x,P,u,in)
%
% IN:
%   - x: none
%   - P: the response model parameter vector
%   - u: the current input to the observer
%   - in: further quantities handed to the function
%
% OUT:
%   - fx:  learner
% delta rule with separate learning rates for mean and precision

% to do in all new f functions check exp/log where needed, check that x is passed in correctly

learning_mean = 1 / (1 + exp(-theta_params(1))) ;
learning_prec = 1 / (1 + exp(-theta_params(2))) ;

pe = u(3) - x(1) ; % diff between actual and expected isi value


% update mean/precision using the pe
target_prec = 1 / (abs(pe) + eps)  ; % target precision is proportional to 1 / |pe| capped
new_prec = (1 - learning_prec) * x(2) + learning_prec * log(target_prec) ;  % if pe very small then this right hand side cancels out as log 1 is 0

post_mean =  x(1) + learning_mean * pe ; % kalman gain ? do this or not ?
fx = [post_mean; new_prec] ; % look into changing this to have same format/num states as x ?
