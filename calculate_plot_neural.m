function [] = calculate_plot_neural(Ns, Mtype, Gt, cases, neuralInd, isAuditory)



    right_bound = 1:min(500, size(cases(1).Y{1}, 2)); % either take all of the trials or only till 500
    if (isAuditory)
        % Preallocate cell arrays for all cases
        alpha_amp_values = cell(length(cases), 1);
        alpha_phase_values = cell(length(cases), 1);

        % Extract data for each case
        for i = 1:length(cases)
            alpha_amp_values{i} = cellfun(@(x) x(neuralInd, right_bound), cases(i).Y, 'UniformOutput', false);
            alpha_phase_values{i} = cellfun(@(x) x(neuralInd + 1, right_bound), cases(i).Y, 'UniformOutput', false);
        end

        % Individual case plots
        for i = 1:length(cases)
            % Phase plot for this case
            figure;
            plot(alpha_phase_values{i}{1}, 'LineWidth', 0.8);
            xlabel('Trial');
            ylabel('phase');
            phaseTitle = sprintf('Alpha phase with model %s/G%d and %d subjects for case %s', Mtype, Gt, Ns, cases(i).title);
            if (Gt == 7); phaseTitle = sprintf('Delta Phase term (2pi*f*(isi-mu)) case %s', cases(i).title); end
            title(phaseTitle);
        end

        % Comparison plots across all cases
        % Amplitude histogram comparison
        compPlot = figure('Name', 'Amplitude Histogram Comparison');
        ax1 = axes('Parent', compPlot);
        colors = lines(length(cases));
        for i = 1:length(cases)
            histogram(ax1, alpha_amp_values{i}{1}, 'NumBins', 15, 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        title(ax1, sprintf('Amplitude spread histogram of model %s/G%d and %d subjects', Mtype, Gt, Ns));
        legend(cases.title)


        % Phase histogram comparison
        compPlot = figure('Name', 'Phase Histogram Comparison');
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            histogram(ax1, alpha_phase_values{i}{1}, 'NumBins', 15, 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        title(ax1, sprintf('Phase spread histogram of model %s/G%d and %d subjects', Mtype, Gt, Ns));
        legend(cases.title)


        % Amplitude line comparison
        compPlot = figure('Name', 'Amplitude Comparison');
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            plot(ax1, alpha_amp_values{i}{1}, 'Color', colors(i,:), 'LineWidth', 0.8);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        title(ax1, 'Amplitude values across cases');
        legend(cases.title)



        % Phase line comparison
        compPlot = figure('Name', 'Phase Comparison');
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            plot(ax1, alpha_phase_values{i}{1}, 'Color', colors(i,:), 'LineWidth', 0.8);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        title(ax1, 'Phase values across cases');
        legend(cases.title)
    else
        % Visual case: bilateral amplitude (left & right)
        % neuralInd should be [idx_left_amp, idx_right_amp]
        idx_left = neuralInd(1);
        idx_right = neuralInd(2);

        % Extract left and right amplitudes for each case
        left_amp_values = cell(length(cases), 1);
        right_amp_values = cell(length(cases), 1);

        % To do : add phase extraction and comparison, currently both sides have the same phase

        for i = 1:length(cases)
            left_amp_values{i} = cellfun(@(x) x(idx_left, right_bound), cases(i).Y, 'UniformOutput', false);
            right_amp_values{i} = cellfun(@(x) x(idx_right, right_bound), cases(i).Y, 'UniformOutput', false);
        end

        % Subplot helper: create a figure with two rows (left top, right bottom)
        colors = lines(length(cases));

        % 1) Individual case: left vs right amplitudes on same figure (subplots)
        for i = 1:length(cases)
            figure('Name', sprintf('Case %s: Left and Right Amplitudes', cases(i).title));
            subplot(2,1,1);
            plot(left_amp_values{i}{1}, 'LineWidth', 0.8, 'Color', 'b');
            ylabel('Amplitude (µV)');
            title(sprintf('Left hemisphere alpha amplitude, case %s', cases(i).title));
            subplot(2,1,2);
            plot(right_amp_values{i}{1}, 'LineWidth', 0.8, 'Color', 'r');
            xlabel('Trial');
            ylabel('Amplitude (µV)');
            title(sprintf('Right hemisphere alpha amplitude, case %s', cases(i).title));
        end

        % 1) Individual case: left vs right amplitudes on same figure (subplots)
        figure('Name', sprintf('Case: Left Amplitudes'));
        for i = 1:length(cases)
            subplot(4,1,i);
            plot(left_amp_values{i}{1}, 'LineWidth', 0.8, 'Color', 'b');
            ylabel('Amplitude (µV)');
            xlabel('Trial');
            title(sprintf('Left hemisphere alpha amplitude, case %s', cases(i).title));

        end

        % Individual case: left vs right amplitudes on same figure (subplots)
        figure('Name', sprintf('Case: Right Amplitudes'));
        for i = 1:length(cases)
            subplot(4,1,i);
            plot(right_amp_values{i}{1}, 'LineWidth', 0.8, 'Color', 'b');
            ylabel('Amplitude (µV)');
            xlabel('Trial');
            title(sprintf('Right hemisphere alpha amplitude, case %s', cases(i).title));

        end


        % % Comparison across cases: left amplitude line plots
        % figure('Name', 'Left Amplitude Comparison');
        % for i = 1:length(cases)
        %     plot(left_amp_values{i}{1}, 'Color', colors(i,:), 'LineWidth', 0.8);
        %     hold on;
        % end
        % hold off;
        % xlabel('Trial');
        % ylabel('Left amplitude (µV)');
        % title(sprintf('Left hemisphere alpha amplitude across conditions, model %s/G%d', Mtype, Gt));
        % legend(cases.title);

        % % Comparison across cases: right amplitude line plots
        % figure('Name', 'Right Amplitude Comparison');
        % for i = 1:length(cases)
        %     plot(right_amp_values{i}{1}, 'Color', colors(i,:), 'LineWidth', 0.8);
        %     hold on;
        % end
        % hold off;
        % xlabel('Trial');
        % ylabel('Right amplitude (µV)');
        % title(sprintf('Right hemisphere alpha amplitude across conditions, model %s/G%d', Mtype, Gt));
        % legend(cases.title);

        % % Histograms: left amplitudes across cases
        % figure('Name', 'Left Amplitude Histogram');
        % for i = 1:length(cases)
        %     histogram(left_amp_values{i}{1}, 'NumBins', 15, 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
        %     hold on;
        % end
        % hold off;
        % title(sprintf('Left amplitude distribution, model %s/G%d', Mtype, Gt));
        % legend(cases.title);

        % % Histograms: right amplitudes across cases
        % figure('Name', 'Right Amplitude Histogram');
        % for i = 1:length(cases)
        %     histogram(right_amp_values{i}{1}, 'NumBins', 15, 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
        %     hold on;
        % end
        % hold off;
        % title(sprintf('Right amplitude distribution, model %s/G%d', Mtype, Gt));
        % legend(cases.title);
    end



end


% function [] = calculate_plot_neural(Ns, Mtype, Gt,  U1, Y1, U2, Y2, ind)

%     % may be worth only looking at go trials (where visual input = 1)

%     % ind represents the index at which the neural data starts, phase always after (i.e if ind is 3 then amp is at index position 3 and phase at position 4)


%     right_bound = 1:min(500, size(Y1{1}, 2)) ; % either take all of the trials or only till 500
%     alpha_amp_values_PP = cellfun(@(x) x(ind,right_bound), Y1, 'UniformOutput', false); % here we want the amp for all subjs across all trials (go/no-go)
%     alpha_phase_values_PP = cellfun(@(x) x(ind + 1,right_bound ), Y1, 'UniformOutput', false);

%     % same but for unpredictable case, pass in y2
%     alpha_amp_values_UP = cellfun(@(x) x(ind,right_bound), Y2, 'UniformOutput', false);
%     alpha_phase_values_UP = cellfun(@(x) x(ind + 1,right_bound ), Y2, 'UniformOutput', false);


%     compPlot = figure('Name', 'PP/UP Amp Histogram');
%     ax1 = axes('Parent', compPlot);
%     histogram(ax1, alpha_amp_values_PP{1}, 'NumBins' , 15,   'FaceColor', 'blue');
%     hold(ax1, 'on');
%     histogram(alpha_amp_values_UP{1}, 'NumBins' , 15,  'FaceColor', 'red');
%     hold(ax1, 'off');
%     title(ax1, ['PP vs UP amplitude spread histogram  of model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects' ]);
%     legend('PP', 'UP');


%     figure;
%     plot(alpha_phase_values_PP{1}, 'LineWidth',0.8)
%     xlabel('Trial')
%     ylabel('phase')
%     phaseTitle = ['Alpha phase with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ] ;
%     if (Gt == 7); phaseTitle = 'Delta Phase term (2pif * (isi-mu)) case PP' ; end
%     title(phaseTitle);    %% plotting histograms

%     compPlot = figure('Name', 'PP/UP phase Histogram');
%     ax1 = axes('Parent', compPlot);
%     histogram(ax1, alpha_phase_values_PP{1}, 'NumBins' , 15,   'FaceColor', 'blue');
%     hold(ax1, 'on');
%     histogram(alpha_phase_values_UP{1}, 'NumBins' , 15,  'FaceColor', 'red');
%     hold(ax1, 'off');
%     title(ax1, ['PP vs UP delta phase spread histogram of model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects' ]);
%     legend('PP', 'UP');

%     figure;
%     plot(alpha_phase_values_UP{1}, 'LineWidth',0.8)
%     xlabel('Trial')
%     ylabel('phase')
%     phaseTitle = ['Alpha phase with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ] ;
%     if (Gt == 7); phaseTitle = 'Delta Phase term (2pif * (isi-mu)) case UP' ; end
%     title(phaseTitle);    %% plotting histograms


%     compPlot = figure('Name', 'PP/UP amplitude');
%     ax1 = axes('Parent', compPlot);
%     plot(ax1, alpha_amp_values_PP{1}, 'Color', 'blue');
%     hold(ax1, 'on');
%     plot(alpha_amp_values_UP{1}, 'Color', 'red');
%     hold(ax1, 'off');
%     title(ax1, 'PP vs UP values of amplitude');
%     legend('PP', 'UP');

%     compPlot = figure('Name', 'PP/UP phase');
%     ax1 = axes('Parent', compPlot);
%     plot(ax1, alpha_phase_values_PP{1}, 'Color', 'blue');
%     hold(ax1, 'on');
%     plot(ax1, alpha_phase_values_UP{1}, 'Color', 'red');
%     hold(ax1, 'off');
%     title(ax1, 'PP vs UP values of phase');
%     legend('PP', 'UP');

%     % plotArrows(alpha_phase_values_UP{1}, alpha_amp_values_UP{1}, 'Phase' , 'Amplitude' , ['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP']) ;


%     % for case of looking at how the x coordinate changes in the cartesian plane during oscillation
%     if (Gt == 1 && size(Y1{1}, 1) >= ind + 2)

%         % Extract alpha values for both cases
%         alpha_x_values_PP = cellfun(@(x) x(ind + 2, right_bound), Y1, 'UniformOutput', false);
%         alpha_x_values_UP = cellfun(@(x) x(ind + 2, right_bound), Y2, 'UniformOutput', false);

%         % alpha_y_values_PP = cellfun(@(x) x(ind + 3, right_bound), Y1, 'UniformOutput', false);
%         % alpha_y_values_UP = cellfun(@(x) x(ind + 3, right_bound), Y2, 'UniformOutput', false);

%         % Check if we have vectors that need concatenation
%         % has_vectors = cellfun(@(x) numel(x) > 1, alpha_x_values_PP{1}(1 , 1));

%         % Vectorized concatenation using cell2mat and reshape
%         if (~isscalar(alpha_x_values_PP{1}(1 , 1)))
%             % Convert each cell element to column vector and concatenate all trials
%             type = '(concatenated vectors)' ;
%             alpha_x_concat_PP = cell2mat(cellfun(@(x) x(:), alpha_x_values_PP{1}, 'UniformOutput', false));
%             % Convert each cell element to column vector and concatenate all trials
%             alpha_x_concat_UP = cell2mat(cellfun(@(x) x(:), alpha_x_values_UP{1}, 'UniformOutput', false));

%             %     alpha_y_concat_PP = cell2mat(cellfun(@(x) x(:), alpha_y_values_PP{1}, 'UniformOutput', false));
%             %     % Convert each cell element to column vector and concatenate all trials
%             %     alpha_y_concat_UP = cell2mat(cellfun(@(x) x(:), alpha_y_values_UP{1}, 'UniformOutput', false));
%         else
%             type = '(single values at t)' ;
%             alpha_x_concat_PP = alpha_x_values_PP{1};
%             alpha_x_concat_UP = alpha_x_values_UP{1};
%             % alpha_y_concat_PP = alpha_y_values_PP{1};
%             % alpha_y_concat_UP = alpha_y_values_UP{1};
%         end
%         disp(type) ;

%         % Plotting
%         compPlot = figure('Name', 'PP/UP amplitude/X value');
%         ax1 = axes('Parent', compPlot);
%         plot(ax1, alpha_x_concat_PP, 'Color', 'blue');
%         hold(ax1, 'on');
%         plot(alpha_x_concat_UP, 'Color', 'red');
%         hold(ax1, 'off');
%         title(ax1, 'PP vs UP values of x during oscillation');
%         legend('PP', 'UP');

%         % not interesting, basically similar to x but shifted a bit
%         % compPlot = figure('Name', 'PP/UP amplitude/Y value');
%         % ax1 = axes('Parent', compPlot);
%         % plot(ax1, alpha_y_concat_PP, 'Color', 'blue');
%         % hold(ax1, 'on');
%         % plot(alpha_y_concat_UP, 'Color', 'red');
%         % hold(ax1, 'off');
%         % title(ax1, 'PP vs UP values of Y during oscillation');
%         % legend('PP', 'UP');


%     end



% end

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

