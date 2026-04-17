function [amp, phase , x_final] = hopf_oscillator(precision, time, dt, frequency, plot)
    %% Kuramoto model in Cartesian coordinates (Hopf oscillators)
    % clear; clc;
    arguments

        precision = 1 ;
        time = 30 ;
        dt = 0.001 ;
        frequency = 1 ;
        plot logical = false

    end



    % -----------------------
    % Parameters
    % -----------------------
    N = 1;                 % number of oscillators, def = 1
    K = 1.0;                % coupling strength, def = 1.0
    % lambda = 1.0 ;           % amplitude parameter, def = 1.0
    lambda = 1.0 * (precision) ; % the higher the precision the higher the amplitude,
    omega = frequency * 2 * pi;   % natural frequencies, def = 2 pi

    % T  = 30;                % simulation time, def = 30
    % dt = 0.001;
    tspan = 0:dt:time;

    % -----------------------
    % Initial conditions
    % -----------------------
    theta0 = 2*pi*rand(N,1);
    r0 = 1;

    x0 = r0*cos(theta0);
    % y0 = r0*sin(theta0);
    y0 = r0*sinpi(theta0);

    state0 = [x0; y0];

    % -----------------------
    % Integrate
    % -----------------------
    opts = odeset('RelTol',1e-6,'AbsTol',1e-8);
    [t, sol] = ode45(@(t,s) hopf_cartesian(t,s,N,omega,K,lambda), ...
        tspan, state0, opts);

    x = sol(:,1:N)';
    y = sol(:,N+1:end)';

    % -----------------------
    % Phase + amplitude + order parameter
    % -----------------------
    theta = atan2(y, x);
    amplitude = x.^2 + y.^2;
    R = abs(mean(exp(1i*theta),1));
    phase = theta' ;
    amp = amplitude ;
    x_final = x ;

    if plot == 0
        return
    end

    % -----------------------
    % Plot
    % -----------------------
    figure;

    subplot(1,4,1)
    plot(t, theta','LineWidth',0.8)
    xlabel('Time')
    ylabel('Phase')


    subplot(1,4,2)
    plot(t, amplitude,'k','LineWidth',2)
    xlabel('Time')
    ylabel('Amplitude')


    subplot(1,4,3)
    plot(t, x,'k','LineWidth',2)
    hold all
    plot(t, y,'b','LineWidth',2)
    xlabel('Time')
    ylabel('x(t), y(t)')

    subplot(1,4,4)
    plot(x, y,'k','LineWidth',2)
    xlabel('x(t)')
    ylabel('y(t)')
    axis([-1 1 -1 1])

    set(gcf,'Color','w')

end

%% -----------------------
% ODE function
% -----------------------
function dsdt = hopf_cartesian(~, s, N, omega, K, lambda)

    x = s(1:N);
    y = s(N+1:end);

    r2 = x.^2 + y.^2;

    % can manipulate lambda and multiply it by precision

    dx = (lambda - r2).*x - omega.*y;
    dy = (lambda - r2).*y + omega.*x;

    % Kuramoto-style mean-field coupling
    dx = dx + K*(mean(x) - x);
    dy = dy + K*(mean(y) - y);

    dsdt = [dx; dy];
end

% idea to manipulate phase is :
% phase_input = phase_value ;
% x_phase_change  = cos(phase_value) ; % can multiple by amplitude here as well
% y_phase_change = sin(phase_value) ;
% dx = dx + K * (x_phase_change  - x) ;
% dy = dy + K * (y_phase_change  - y) ;





