function [] = calculate_plot_neural(Ns, Mtype, Gt,  U1, Y1, U2, Y2)

    % Extract go trials (where visual input = 1)
    % At the start of calculate_plot_neural

    % if (size(Y1{1}, 1) == 2 || size(Y1{1}, 1) == 3) % check rows to get correct ind for amp/phase
    if (Gt == 5 || Gt == 4)
        ind = 1  ; % [amp phase] or [amp phase x] % in other gt
    else
        ind = 3 ; % [c rt amp phase] % in case of gt being 7
    end
    disp(["ind is : "  ind]) % ind represents the index at which the neural data starts
    disp(["Ouput num of vals : "  num2str(size(Y1{1}, 1))])

    disp(["First five of Y1 : "  ])
    disp(Y1{1}(:, 1:5)) ;


    right_bound = 1:500 ;
    alpha_amp_values_PP = cellfun(@(x) x(ind,right_bound), Y1, 'UniformOutput', false); % here we want the amp for all subjs across all trials (go/no-go)
    alpha_phase_values_PP = cellfun(@(x) x(ind + 1,right_bound ), Y1, 'UniformOutput', false);

    % same but for unpredictable case, pass in y2
    alpha_amp_values_UP = cellfun(@(x) x(ind,right_bound), Y2, 'UniformOutput', false);
    alpha_phase_values_UP = cellfun(@(x) x(ind + 1,right_bound ), Y2, 'UniformOutput', false);



    % plot predictable case
    % figure ;
    % h = histogram(alpha_amp_values_PP{1} , 15);  %
    % h.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Alpha amplitude histogram with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

    compPlot = figure('Name', 'PP/UP Amp Histogram');
    ax1 = axes('Parent', compPlot);
    histogram(ax1, alpha_amp_values_PP{1}, 'NumBins' , 15,   'FaceColor', 'blue');
    hold(ax1, 'on');
    histogram(alpha_amp_values_UP{1}, 'NumBins' , 15,  'FaceColor', 'red');
    hold(ax1, 'off');
    title(ax1, 'PP vs UP histogram spread of amplitude');
    legend('PP', 'UP');


    figure;
    plot(alpha_amp_values_PP{1}, 'LineWidth',0.8)
    xlabel('Trial')
    ylabel('Amplitude')
    title(['Alpha amplitude  with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

    figure;
    plot(alpha_phase_values_PP{1}, 'LineWidth',0.8)
    xlabel('Trial')
    ylabel('phase')
    phaseTitle = ['Alpha phase with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ] ;
    if (Gt == 7); phaseTitle = 'Delta Phase term (2pif * (isi-mu)) case PP' ; end
    title(phaseTitle);    %% plotting histograms

    compPlot = figure('Name', 'PP/UP phase Histogram');
    ax1 = axes('Parent', compPlot);
    histogram(ax1, alpha_phase_values_PP{1}, 'NumBins' , 15,   'FaceColor', 'blue');
    hold(ax1, 'on');
    histogram(alpha_phase_values_UP{1}, 'NumBins' , 15,  'FaceColor', 'red');
    hold(ax1, 'off');
    title(ax1, 'PP vs UP histogram spread of phase');
    legend('PP', 'UP');

    % figure ;
    % h_rt = histogram(alpha_phase_values_PP{1});  %
    % h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Alpha phase histogram with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ]);

    % plotArrows(alpha_phase_values_PP{1}, alpha_amp_values_PP{1} , 'Phase' , 'Amplitude' , ['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP']) ;


    % UNPREDICTABLE case plotting

    % figure ;
    % h = histogram(alpha_amp_values_UP{1} , 15);  %
    % h.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Alpha amplitude histogram with model ' Mtype ' /G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ]);    %% plotting histograms


    figure;
    plot(alpha_amp_values_UP{1}, 'LineWidth',0.8)
    xlabel('Trial')
    ylabel('Amplitude')
    title(['Alpha amplitude  with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ]);

    figure;
    plot(alpha_phase_values_UP{1}, 'LineWidth',0.8)
    xlabel('Trial')
    ylabel('phase')
    phaseTitle = ['Alpha phase with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ] ;
    if (Gt == 7); phaseTitle = 'Delta Phase term (2pif * (isi-mu)) case UP' ; end
    title(phaseTitle);    %% plotting histograms
    % figure ;
    % h_rt = histogram(alpha_phase_values_UP{1});  %
    % h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Alpha phase histogram with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ]);

    % plotArrows(alpha_phase_values_UP{1}, alpha_amp_values_UP{1}, 'Phase' , 'Amplitude' , ['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP']) ;


    if (Gt ~=7 && size(Y1{1}, 1) >= 3) % in case of [amp phase x y] for gt of 5 4 kuramoto model
        % here check if x(ind + 2) is single amp value or sequence at trial t before/while extracting
        % and concatenate if multiple arrays at each trial point
        % Extract alpha values for both cases
        alpha_x_values_PP = cellfun(@(x) x(ind + 2, right_bound), Y1, 'UniformOutput', false);
        alpha_x_values_UP = cellfun(@(x) x(ind + 2, right_bound), Y2, 'UniformOutput', false);

        alpha_y_values_PP = cellfun(@(x) x(ind + 3, right_bound), Y1, 'UniformOutput', false);
        alpha_y_values_UP = cellfun(@(x) x(ind + 3, right_bound), Y2, 'UniformOutput', false);

        % Check if we have vectors that need concatenation
        % has_vectors = cellfun(@(x) numel(x) > 1, alpha_x_values_PP{1}(1 , 1));

        % Vectorized concatenation using cell2mat and reshape
        if (~isscalar(alpha_x_values_PP{1}(1 , 1)))
            % Convert each cell element to column vector and concatenate all trials
            type = '(concatenated vectors)' ;
            alpha_x_concat_PP = cell2mat(cellfun(@(x) x(:), alpha_x_values_PP{1}, 'UniformOutput', false));
            % Convert each cell element to column vector and concatenate all trials
            alpha_x_concat_UP = cell2mat(cellfun(@(x) x(:), alpha_x_values_UP{1}, 'UniformOutput', false));

            alpha_y_concat_PP = cell2mat(cellfun(@(x) x(:), alpha_y_values_PP{1}, 'UniformOutput', false));
            % Convert each cell element to column vector and concatenate all trials
            alpha_y_concat_UP = cell2mat(cellfun(@(x) x(:), alpha_y_values_UP{1}, 'UniformOutput', false));
        else
            type = '(single values at t)' ;
            alpha_x_concat_PP = alpha_x_values_PP{1};
            alpha_x_concat_UP = alpha_x_values_UP{1};
            alpha_y_concat_PP = alpha_y_values_PP{1};
            alpha_y_concat_UP = alpha_y_values_UP{1};
        end
        disp(type) ;

        % Plotting
        compPlot = figure('Name', 'PP/UP amplitude/X value');
        ax1 = axes('Parent', compPlot);
        plot(ax1, alpha_x_concat_PP, 'Color', 'blue');
        hold(ax1, 'on');
        plot(alpha_x_concat_UP, 'Color', 'red');
        hold(ax1, 'off');
        title(ax1, 'PP vs UP values of x during oscillation');
        legend('PP', 'UP');

        % not interesting, basically similar to x but shifted a bit
        % compPlot = figure('Name', 'PP/UP amplitude/Y value');
        % ax1 = axes('Parent', compPlot);
        % plot(ax1, alpha_y_concat_PP, 'Color', 'blue');
        % hold(ax1, 'on');
        % plot(alpha_y_concat_UP, 'Color', 'red');
        % hold(ax1, 'off');
        % title(ax1, 'PP vs UP values of Y during oscillation');
        % legend('PP', 'UP');



        % figure;
        % plot(alpha_x_concat_PP, 'LineWidth', 0.8)
        % title(['Alpha X ' type ' with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP']);
        % xlabel('Trial/Time Point');
        % ylabel('x');


        % figure;
        % plot(alpha_x_concat_UP, 'LineWidth', 0.8)
        % title(['Alpha X ' type ' with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP']);
        % xlabel('Trial/Time Point');
        % ylabel('x');


        % alpha_x_values_PP = cellfun(@(x) x(ind + 2,right_bound ), Y1, 'UniformOutput', false);
        % alpha_x_values_UP = cellfun(@(x) x(ind + 2,right_bound ), Y2, 'UniformOutput', false);

        % figure;
        % plot(alpha_x_values_PP{1}, 'LineWidth',0.8)
        % xlabel('Trial')
        % ylabel('x')
        % title(['Alpha X  with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

        % figure;
        % plot(alpha_x_values_UP{1}, 'LineWidth',0.8)
        % xlabel('Trial')
        % ylabel('x')
        % title(['Alpha X  with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ]);    %% plotting histograms

    end

    compPlot = figure('Name', 'PP/UP amplitude');
    ax1 = axes('Parent', compPlot);
    plot(ax1, alpha_amp_values_PP{1}, 'Color', 'blue');
    hold(ax1, 'on');
    plot(alpha_amp_values_UP{1}, 'Color', 'red');
    hold(ax1, 'off');
    title(ax1, 'PP vs UP values of amplitude');
    legend('PP', 'UP');

    compPlot = figure('Name', 'PP/UP phase');
    ax1 = axes('Parent', compPlot);
    plot(ax1, alpha_phase_values_PP{1}, 'Color', 'blue');
    hold(ax1, 'on');
    plot(ax1, alpha_phase_values_UP{1}, 'Color', 'red');
    hold(ax1, 'off');
    title(ax1, 'PP vs UP values of phase');
    legend('PP', 'UP');


end

function [] = plotArrows (Xdata, Ydata, xLabel, yLabel, plot_title)
    figure;
    hold on;

    % Plot the main trajectory line
    plot(Xdata, Ydata, 'b-', 'LineWidth', 1.5);

    % Add distinctive markers for start and end points
    plot(Xdata(1), Ydata(1), 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 2);
    plot(Xdata(end), Ydata(end), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'LineWidth', 2);

    % Add labels for start and end points
    text(Xdata(1), Ydata(1), 'Start', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
    text(Xdata(end), Ydata(end), 'End', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontSize', 10, 'FontWeight', 'bold');

    % Compute differences (direction vectors)
    dx = diff(Xdata);
    dy = diff(Ydata);

    % Select every 5th data point for arrows
    arrow_indices = 1:5:length(Xdata)-1;

    % Add arrows at selected points
    quiver(Xdata(arrow_indices), ...
        Ydata(arrow_indices), ...
        dx(arrow_indices), dy(arrow_indices), ...
        0.3, 'Color', 'r', 'LineWidth', 0.8, 'MaxHeadSize', 0.9);

    % Add legend
    legend('Trajectory', 'Start', 'End', 'Location', 'best');


    % Set axis properties
    axis equal;
    xlabel(xLabel);
    ylabel(yLabel);
    title(plot_title) ;

    hold off;


    % other method/design
    % figure;
    % plot(alpha_phase_values_UP{1}, alpha_amp_values_UP{1}, 'b-', 'LineWidth', 1.5);
    % hold on ;
    % % Compute differences (direction vectors)
    % dx = diff(alpha_phase_values_UP{1});
    % dy = diff(alpha_amp_values_UP{1});

    % % Add arrows at each segment using quiver
    % quiver(alpha_phase_values_UP{1}(1:end-1), alpha_amp_values_UP{1}(1:end-1), ...
    %     dx, dy, 0.3, 'Color', 'r', 'LineWidth', 0.8, 'MaxHeadSize', 0.9);
    % axis equal;
    % title(['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP']);
    % xlabel('Phase');
    % ylabel('Amplitude');
    % hold off;


end


% alternative idea for taking amplitude and simulating sin wave based on that
% if (Gt == 4) % in the case of kuramoto model, take amp, run through sin simulation, and represent it across timepoints
%         right_bound = 1:75; % look at first 50 trials

%         alpha_amp_values_PP = cellfun(@(x) x(ind,right_bound), Y2, 'UniformOutput', false);
%         alpha_amp_values_PP = alpha_amp_values_PP{1}
%         alpha_phase_values_PP = cellfun(@(x) x(ind + 1,right_bound), Y2, 'UniformOutput', false);
%         alpha_phase_values_PP = alpha_phase_values_PP{1} ;

%         isi_values = U2(3, right_bound) % third row has isis


%         % Example data (replace with your actual data)
%         % isi_values = [250, 300, 400, 250, 300]; % ms between trials
%         % alpha_amp_values_PP = [1.3, 4, 4.2, 4, 2.8];
%         % alpha_phase_values_PP = [0, pi/4, pi/2, 3*pi/4, pi]; % example phase values

%         % Calculate absolute trial times (in milliseconds)
%         trial_times_ms = cumsum([0, isi_values(1:end-1)]); % [0, 250, 550, 950, 1200] ms
%         % For 50 trials: trial_times_ms = cumsum([0, isi_values(1:end-1)]);

%         % Convert to seconds for plotting
%         trial_times_sec = trial_times_ms / 1000;

%         % Parameters for continuous sine wave
%         frequency = 10; % Hz (alpha wave)
%         sampling_rate = 1000; % Hz (1 sample per ms for smooth plotting)
%         dt = 1/sampling_rate; % time step in seconds

%         % Create continuous time vector from start to end
%         total_duration_sec = (sum(isi_values)) / 1000; % total time including last ISI
%         time_continuous = 0:dt:total_duration_sec;

%         % Initialize the modulated alpha wave
%         alpha_wave = zeros(size(time_continuous));

%         % Generate continuous alpha wave with modulation at trial points
%         % Method: For each time point, find the nearest trial and modulate based on that trial's amp/phase
%         % Or better: Create an envelope that interpolates between trial amplitudes

%         % Option 1: Simple modulation - apply amplitude and phase at exact trial times
%         for t_idx = 1:length(time_continuous)
%             t_current = time_continuous(t_idx);

%             % Find which trial interval we're in
%             if t_current <= trial_times_sec(1)
%                 % Before first trial - use first trial's parameters
%                 current_amp = alpha_amp_values_PP(1);
%                 current_phase = alpha_phase_values_PP(1);
%             elseif t_current >= trial_times_sec(end)
%                 % After last trial - use last trial's parameters
%                 current_amp = alpha_amp_values_PP(end);
%                 current_phase = alpha_phase_values_PP(end);
%             else
%                 % Find the trial we're currently between
%                 for trial_idx = 1:length(trial_times_sec)-1
%                     if t_current >= trial_times_sec(trial_idx) && t_current < trial_times_sec(trial_idx+1)
%                         % Interpolate amplitude and phase between trials
%                         t1 = trial_times_sec(trial_idx);
%                         t2 = trial_times_sec(trial_idx+1);
%                         prop = (t_current - t1) / (t2 - t1);

%                         current_amp = alpha_amp_values_PP(trial_idx) * (1-prop) + alpha_amp_values_PP(trial_idx+1) * prop;
%                         current_phase = alpha_phase_values_PP(trial_idx) * (1-prop) + alpha_phase_values_PP(trial_idx+1) * prop;
%                         break;
%                     end
%                 end
%             end

%             % Generate alpha wave at this time point
%             alpha_wave(t_idx) = current_amp * sin(2*pi*frequency * t_current + current_phase);
%         end

%         % Plot the continuous alpha wave
%         figure('Position', [100, 100, 1200, 600]);
%         plot(time_continuous, alpha_wave, 'b-', 'LineWidth', 1);
%         hold on;

%         % Mark trial times with markers
%         plot(trial_times_sec, alpha_amp_values_PP .* sin(2*pi*frequency * trial_times_sec + alpha_phase_values_PP), ...
%             'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

%         % Add vertical lines at trial times
%         for i = 1:length(trial_times_sec)
%             xline(trial_times_sec(i), 'k--', 'LineWidth', 0.5);
%         end

%         xlabel('Time (seconds)');
%         ylabel('Alpha Wave Amplitude');
%         title(sprintf('Continuous 10 Hz Alpha Wave Modulated at Trial Times\nISI: [%s] ms', num2str(isi_values)));
%         legend('Continuous Alpha Wave', 'Trial Modulation Points', 'Location', 'best');
%         grid on;
%         hold off;

%         % Option 2: Create envelope plot showing amplitude modulation
%         figure('Position', [100, 100, 1200, 800]);

%         subplot(3,1,1);
%         plot(time_continuous, alpha_wave, 'b-', 'LineWidth', 1);
%         hold on;
%         plot(trial_times_sec, alpha_amp_values_PP .* sin(2*pi*frequency * trial_times_sec + alpha_phase_values_PP), ...
%             'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
%         xlabel('Time (seconds)');
%         ylabel('Signal');
%         title('Continuous Alpha Wave (10 Hz)');
%         grid on;

%         subplot(3,1,2);
%         % Plot amplitude envelope (interpolated between trials)
%         amp_envelope = interp1(trial_times_sec, alpha_amp_values_PP, time_continuous, 'linear', 'extrap');
%         plot(time_continuous, amp_envelope, 'r-', 'LineWidth', 2);
%         hold on;
%         plot(trial_times_sec, alpha_amp_values_PP, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
%         xlabel('Time (seconds)');
%         ylabel('Amplitude Envelope');
%         title('Amplitude Modulation Envelope');
%         grid on;

%         subplot(3,1,3);
%         % Plot phase modulation
%         phase_envelope = interp1(trial_times_sec, alpha_phase_values_PP, time_continuous, 'linear', 'extrap');
%         plot(time_continuous, phase_envelope, 'g-', 'LineWidth', 2);
%         hold on;
%         plot(trial_times_sec, alpha_phase_values_PP, 'mo', 'MarkerSize', 8, 'MarkerFaceColor', 'm');
%         xlabel('Time (seconds)');
%         ylabel('Phase (radians)');
%         title('Phase Modulation');
%         grid on;

%         % Print trial timing information
%         fprintf('\nTrial Timing Information:\n');
%         fprintf('------------------------\n');
%         fprintf('Trial\tISI(ms)\tTime(ms)\tTime(s)\tAmplitude\tPhase(rad)\n');
%         for i = 1:length(isi_values)
%             if i == 1
%                 time_ms = 0;
%             else
%                 time_ms = sum(isi_values(1:i-1));
%             end
%             fprintf('%d\t%d\t\t%d\t\t%.3f\t%.2f\t\t%.2f\n', ...
%                 i, isi_values(i), time_ms, time_ms/1000, alpha_amp_values_PP(i), alpha_phase_values_PP(i));
%         end
%         fprintf('Total duration: %.3f seconds\n', total_duration_sec);

%         % % Option 3: Create a spectrogram to see frequency content
%         % figure('Position', [100, 100, 1200, 400]);
%         % spectrogram(alpha_wave, 256, 250, 256, sampling_rate, 'yaxis');
%         % title('Spectrogram of Modulated Alpha Wave');
%         % ylim([0, 30]); % Focus on alpha range
%     end

