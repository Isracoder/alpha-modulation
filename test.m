function [] = test()

    f = 10 ;
    x = 2*pi*f*[-500 -400 -300 -200 -100 0 100 200 300 400 500 ] ;
    disp(x) ;
    y =sin(x) ;
    y2 =sinpi(x) ;
    disp("sin: ")
    disp(y) ;

    % figure;
    % plot(x , y, 'LineWidth',0.8) ;
    % xlabel('X')
    % ylabel('Val')
    % title("Value sin")

    compPlot = figure('Name', 'Sin');
    ax1 = axes('Parent', compPlot);
    plot(ax1, y, 'Color', 'blue');
    hold(ax1, 'on');
    plot(ax1, y2, 'Color', 'red');
    hold(ax1, 'off');
    title(ax1, 'sin');
    legend('sin1', 'sin2');


    % fs = 10;
    % t = 0:1/fs:1;
    % disp(t) ;
    % i = sin(2*pi*10*t) + randn(size(t))/10;
    % q = sin(2*pi*20*t) + randn(size(t))/10;
    % y = modulate(i, 70, fs, 'qam', q); % Quadrature AM

    % figure;
    % plot(y, 'LineWidth',0.8)
    % xlabel('X')
    % ylabel('Val')
    % title("Modulation")

    figure ;
    fs = 1000; % Sampling frequency
    fc = 200;  % Carrier frequency
    endTime = 1 ;
    t = (0:1/fs:endTime)'; % Time vector
    disp(0:0.1:1) ;
    x = sin(2*pi*30*t) + 2*sin(2*pi*60*t); % Message signal
    fDev = 50; % Frequency deviation
    y = makeFM(x, fc, fs, fDev); % Modulated signal
    plot(t, x, 'r', t, y, 'b');
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Original Signal', 'Modulated Signal');


end


function [s, t] = makeFM(x, Fc, Fs, strength)
    % x: input message signal
    % Fc: carrier frequency
    % Fs: sampling frequency (must be > 2*Fc per Nyquist criterion)
    % strength: frequency deviation constant

    x = x(:);
    t = (0 : numel(x) - 1)' / Fs;
    integratedX = cumsum(x) / Fs;
    s = cos(2 * pi * (Fc * t + strength * integratedX));
end