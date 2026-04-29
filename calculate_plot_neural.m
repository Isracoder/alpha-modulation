function [] = calculate_plot_neural(Ns, Mtype, Gt, difficulty,  U1, Y1, U2, Y2, ind)

    % may be worth only looking at go trials (where visual input = 1)

    % ind represents the index at which the neural data starts, phase always after (i.e if ind is 3 then amp is at index position 3 and phase at position 4)


    right_bound = 1:min(500, size(Y1{1}, 2)) ; % either take all of the trials or only till 500
    alpha_amp_values_PP = cellfun(@(x) x(ind,right_bound), Y1, 'UniformOutput', false); % here we want the amp for all subjs across all trials (go/no-go)
    alpha_phase_values_PP = cellfun(@(x) x(ind + 1,right_bound ), Y1, 'UniformOutput', false);

    % same but for unpredictable case, pass in y2
    alpha_amp_values_UP = cellfun(@(x) x(ind,right_bound), Y2, 'UniformOutput', false);
    alpha_phase_values_UP = cellfun(@(x) x(ind + 1,right_bound ), Y2, 'UniformOutput', false);


    compPlot = figure('Name', 'PP/UP Amp Histogram');
    ax1 = axes('Parent', compPlot);
    histogram(ax1, alpha_amp_values_PP{1}, 'NumBins' , 15,   'FaceColor', 'blue');
    hold(ax1, 'on');
    histogram(alpha_amp_values_UP{1}, 'NumBins' , 15,  'FaceColor', 'red');
    hold(ax1, 'off');
    title(ax1, ['PP vs UP amplitude spread histogram  of model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects' ]);
    legend('PP', 'UP');


    figure;
    plot(alpha_phase_values_PP{1}, 'LineWidth',0.8)
    xlabel('Trial')
    ylabel('phase')
    % phaseTitle = ['Alpha phase with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ] ;
    phaseTitle = 'Delta Phase term (2pif * (isi-mu)) case PP'  ;
    title(phaseTitle);    %% plotting histograms

    compPlot = figure('Name', 'PP/UP phase Histogram');
    ax1 = axes('Parent', compPlot);
    histogram(ax1, alpha_phase_values_PP{1}, 'NumBins' , 15,   'FaceColor', 'blue');
    hold(ax1, 'on');
    histogram(alpha_phase_values_UP{1}, 'NumBins' , 15,  'FaceColor', 'red');
    hold(ax1, 'off');
    title(ax1, ['PP vs UP delta phase spread histogram of model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects' ]);
    legend('PP', 'UP');

    figure;
    plot(alpha_phase_values_UP{1}, 'LineWidth',0.8)
    xlabel('Trial')
    ylabel('phase')
    % phaseTitle = ['Alpha phase with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ] ;
    phaseTitle = 'Delta Phase term (2pif * (isi-mu)) case UP' ;
    title(phaseTitle);    %% plotting histograms


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

    if (Gt == 2) % signal detection model
        alpha_full_amp_values_PP = cellfun(@(x) x(6,right_bound), Y1, 'UniformOutput', false);
        alpha_full_amp_values_UP = cellfun(@(x) x(6,right_bound), Y2, 'UniformOutput', false);

        compPlot = figure('Name', 'PP/UP full amplitude');
        ax1 = axes('Parent', compPlot);
        plot(ax1, alpha_full_amp_values_PP{1}, 'Color', 'blue');
        hold(ax1, 'on');
        plot(alpha_full_amp_values_UP{1}, 'Color', 'red');
        hold(ax1, 'off');
        title(ax1, 'PP vs UP values of excitability as (amplitude*phase)');
        legend('PP', 'UP');
    end

    % plotArrows(alpha_phase_values_UP{1}, alpha_amp_values_UP{1}, 'Phase' , 'Amplitude' , ['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP']) ;


    % for case of looking at how the x coordinate changes in the cartesian plane during oscillation
    % if (Gt == ? && size(Y1{1}, 1) >= ind + 2)

    %     % Extract alpha values for both cases
    %     alpha_x_values_PP = cellfun(@(x) x(ind + 2, right_bound), Y1, 'UniformOutput', false);
    %     alpha_x_values_UP = cellfun(@(x) x(ind + 2, right_bound), Y2, 'UniformOutput', false);

    %     % alpha_y_values_PP = cellfun(@(x) x(ind + 3, right_bound), Y1, 'UniformOutput', false);
    %     % alpha_y_values_UP = cellfun(@(x) x(ind + 3, right_bound), Y2, 'UniformOutput', false);

    %     % Check if we have vectors that need concatenation
    %     % has_vectors = cellfun(@(x) numel(x) > 1, alpha_x_values_PP{1}(1 , 1));

    %     % Vectorized concatenation using cell2mat and reshape
    %     if (~isscalar(alpha_x_values_PP{1}(1 , 1)))
    %         % Convert each cell element to column vector and concatenate all trials
    %         type = '(concatenated vectors)' ;
    %         alpha_x_concat_PP = cell2mat(cellfun(@(x) x(:), alpha_x_values_PP{1}, 'UniformOutput', false));
    %         % Convert each cell element to column vector and concatenate all trials
    %         alpha_x_concat_UP = cell2mat(cellfun(@(x) x(:), alpha_x_values_UP{1}, 'UniformOutput', false));

    %         %     alpha_y_concat_PP = cell2mat(cellfun(@(x) x(:), alpha_y_values_PP{1}, 'UniformOutput', false));
    %         %     % Convert each cell element to column vector and concatenate all trials
    %         %     alpha_y_concat_UP = cell2mat(cellfun(@(x) x(:), alpha_y_values_UP{1}, 'UniformOutput', false));
    %     else
    %         type = '(single values at t)' ;
    %         alpha_x_concat_PP = alpha_x_values_PP{1};
    %         alpha_x_concat_UP = alpha_x_values_UP{1};
    %         % alpha_y_concat_PP = alpha_y_values_PP{1};
    %         % alpha_y_concat_UP = alpha_y_values_UP{1};
    %     end
    %     disp(type) ;

    %     % Plotting
    %     compPlot = figure('Name', 'PP/UP amplitude/X value');
    %     ax1 = axes('Parent', compPlot);
    %     plot(ax1, alpha_x_concat_PP, 'Color', 'blue');
    %     hold(ax1, 'on');
    %     plot(alpha_x_concat_UP, 'Color', 'red');
    %     hold(ax1, 'off');
    %     title(ax1, 'PP vs UP values of x during oscillation');
    %     legend('PP', 'UP');

    %     % not interesting, basically similar to x but shifted a bit
    %     % compPlot = figure('Name', 'PP/UP amplitude/Y value');
    %     % ax1 = axes('Parent', compPlot);
    %     % plot(ax1, alpha_y_concat_PP, 'Color', 'blue');
    %     % hold(ax1, 'on');
    %     % plot(alpha_y_concat_UP, 'Color', 'red');
    %     % hold(ax1, 'off');
    %     % title(ax1, 'PP vs UP values of Y during oscillation');
    %     % legend('PP', 'UP');


    % end



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

