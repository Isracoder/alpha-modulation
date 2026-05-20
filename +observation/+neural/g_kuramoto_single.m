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

    gx = zeros(4, 1) ;
    % amp, phase
    % precision = exp(x_states(2)) ; % not used here since they controlled x,y in f function
    % frequency = 10 ;

    % SECOND
    x_osc = x_states(9);
    y_osc = x_states(10);

    amplitude = sqrt(x_osc^2 + y_osc^2);
    phase     = atan2(y_osc, x_osc);


    gx(1) = (amplitude) ;
    gx(2) = (phase) ;
    gx(3) =  x_osc ;
    gx(4) =  y_osc ;



end