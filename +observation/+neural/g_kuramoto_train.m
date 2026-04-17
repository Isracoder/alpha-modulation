function [gx] = g_kuramoto(x_states,phi_params,u_input,inG)
    % [gx] = g_kuramoto(x,P,u,in)
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
    % This function computes a kuramoto style hopf mean coupling model in order to simulate alpha oscillations, and uses the incoming phase to modulate those oscillations

    gx = cell(3, 1) ;
    % amp, phase
    precision = exp(x_states(2)) ;
    stim_time = 5 ;
    dt = 0.1 ;
    frequency = 10 ;

    %   FIRST ATTEMPT
    [amp , phase, x] = neural_mm.hopf_oscillator(precision, stim_time, dt, frequency, false) ;
    gx{1,1} =  (amp) ; % here this should be a sequence of values
    gx{2,1} = (phase) ;
    gx{3,1} =  x ;
    % gx(1) =  (amp) ; % here this should be a sequence of values
    % gx(2) = (phase) ;
    % gx(3) =  x ;


end