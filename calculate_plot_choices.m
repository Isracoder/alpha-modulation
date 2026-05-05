function [] = calculate_plot_choices(Ns, Mtype, Gt, cases, isAuditory, difficulty)
    % CALCULATE_PLOT_CHOICES Plot behavioral metrics across multiple cases
    %
    % Inputs:
    %   cases: Struct array with fields:
    %       .U - input matrix
    %       .Y - cell array of subject data
    %       .title - string for legend/title
    %       .ind - (optional) index for neural data (unused here)

    % Define metrics to extract and plot
    metrics = [
        struct('name', 'Accuracy', 'field', 'accuracy', ...
        'ylabel', 'Accuracy percentage', 'multiplier', 100, 'y_offset', 5, 'show_points', true);
        struct('name', 'Correct RT', 'field', 'mean_RT_correct', ...
        'ylabel', 'Reaction Time (ms)', 'multiplier', 1, 'y_offset', 50, 'show_points', false);
        struct('name', 'Error RT', 'field', 'mean_RT_error', ...
        'ylabel', 'Reaction Time (ms)', 'multiplier', 1, 'y_offset', 50, 'show_points', false);
        struct('name', 'D-prime', 'field', 'mean_dp', ...
        'ylabel', 'd prime averaged', 'multiplier', 1, 'y_offset', 0.5, 'show_points', true)
        ];

    % Only include d-prime if Gt == 2
    if Gt ~= 2
        metrics = metrics(1:3);
    end

    % Preallocate cell arrays for each metric across cases
    for m = 1:length(metrics)
        metrics(m).data = cell(length(cases), 1);
    end

    % Extract data for each case
    for i = 1:length(cases)
        [accuracy, mean_RT_correct, ~, ~, mean_RT_error, mean_dp] = ...
            calculate_choices(Ns, Mtype, Gt, difficulty, cases(i).U, cases(i).Y);

        metrics(1).data{i} = accuracy;
        metrics(2).data{i} = mean_RT_correct;
        metrics(3).data{i} = mean_RT_error;
        if Gt == 2
            metrics(4).data{i} = mean_dp;
        end
    end

    % Plot each metric
    for m = 1:length(metrics)
        % Individual case plots
        % for i = 1:length(cases)
        %     figure;
        %     data = metrics(m).data{i} * metrics(m).multiplier;
        %     histogram(data, 'NumBins', 15, 'FaceAlpha', 0.6);
        %     xlabel(metrics(m).ylabel);
        %     ylabel('Frequency');
        %     title(sprintf('%s distribution for %s (model %s/G%d, n=%d)', ...
        %         metrics(m).name, cases(i).title, Mtype, Gt, Ns));
        % end

        % Comparison plot across all cases
        if length(cases) > 1
            figure;
            hold on;
            colors = lines(length(cases));
            all_means = zeros(1, length(cases));
            all_stds = zeros(1, length(cases));

            for i = 1:length(cases)
                data = metrics(m).data{i} * metrics(m).multiplier;
                all_means(i) = mean(data);
                all_stds(i) = std(data);

                % Bar plot
                bar(i, all_means(i), 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
            end

            % Add error bars
            errorbar(1:length(cases), all_means, all_stds, 'k.', 'LineWidth', 1.5, 'MarkerSize', 10);

            % Add individual points if requested
            if metrics(m).show_points
                for i = 1:length(cases)
                    data = metrics(m).data{i} * metrics(m).multiplier;
                    jitter = (rand(size(data)) - 0.5) * 0.2;
                    scatter(i + jitter, data, 30, colors(i,:), 'filled', 'MarkerFaceAlpha', 0.5);
                end
            end

            % Perform pairwise t-tests
            if Ns > 1
                max_height = max(all_means + all_stds);
                ylim([0, max_height + metrics(m).y_offset * 1.5]);

                for i = 1:length(cases)-1
                    for j = i+1:length(cases)
                        [~, p] = ttest2(metrics(m).data{i}, metrics(m).data{j});
                        if p < 0.05
                            text_x = (i + j) / 2;
                            text(text_x, max_height + metrics(m).y_offset, '*', ...
                                'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold');
                        end
                    end
                end
            end

            xlabel('Condition');
            ylabel(metrics(m).ylabel);
            title(sprintf('Mean %s comparison (model %s/G%d, n=%d per condition, difficulty %d)', ...
                metrics(m).name, Mtype, Gt, Ns , difficulty));
            legend({cases.title}, 'Location', 'best');
            hold off;
        end
    end
end



% function [] = calculate_plot_choices(Ns, Mtype, Gt,  U1, Y1, U2, Y2)

%     [accuracy_PP, mean_RT_correct_PP, std_RT_correct_PP, std_RT_error_PP, mean_RT_error_PP, mean_dp_PP] = calculate_choices(Ns, Mtype, Gt, U1, Y1) ;
%     [accuracy_UP, mean_RT_correct_UP, std_RT_correct_UP, std_RT_error_UP, mean_RT_error_UP, mean_dp_UP] = calculate_choices(Ns, Mtype, Gt, U2, Y2) ;

%     X = categorical({'Predictable' , 'Unpredictable'}) ;

%     % For accuracy (percentage)
%     plot_significance_bar(accuracy_PP, accuracy_UP, ...
%         {'Predictable', 'Unpredictable'}, ...
%         'Accuracy percentage', ...
%         ['Mean Accuracy Graph with observation model: ' num2str(Gt)], ...
%         'multiplier', 100, 'show_individual_points', true);

%     % For reaction time (assuming RT data)
%     plot_significance_bar(mean_RT_correct_PP, mean_RT_correct_UP, ...
%         {'Predictable', 'Unpredictable'}, ...
%         'Reaction Time (ms)', ...
%         ['Mean correct RT Graph with observation model: ' num2str(Gt)], ...
%         'multiplier', 1, 'y_offset_factor', 50);

%     % For reaction time (assuming RT data)
%     plot_significance_bar(mean_RT_error_PP, mean_RT_error_UP, ...
%         {'Predictable', 'Unpredictable'}, ...
%         'Reaction Time (ms)', ...
%         ['Mean error RT Graph with observation model: ' num2str(Gt)], ...
%         'multiplier', 1, 'y_offset_factor', 50);


%     % figure;
%     % bar(X,[mean(accuracy_PP) * 100  mean(accuracy_UP) * 100])
%     % xlabel('Condition');
%     % ylabel('Accuracy percentage');
%     % title(['Mean Accuracy Graph with observation model: ' num2str(Gt)]);

%     % figure ;
%     % bar(X,[mean(mean_RT_correct_PP)  mean(mean_RT_correct_UP) ])
%     % title(['Mean Correct Reaction time (across ' num2str(Ns) ' subjects) and Obs.model ' num2str(Gt)]);    %% plotting histograms
%     % xlabel('Condition');
%     % ylabel('Reaction Time (ms)');


%     % figure;
%     % bar(X,[mean(mean_RT_error_PP)  mean(mean_RT_error_UP)])
%     % xlabel('Condition');
%     % ylabel('Reaction Time (ms)') ;
%     % title(['Mean Incorrect Reaction time (across ' num2str(Ns) ' subjects)  and Obs.model ' num2str(Gt)]);    %% plotting histograms

%     if (Gt == 6) % in case of SDT model plot d prime across conditions
%         figure;
%         bar(X,[mean(mean_dp_PP)  mean(mean_dp_UP)])
%         xlabel('Condition');
%         ylabel('d prime averaged') ;
%         title(['D prime (across ' num2str(Ns) ' subjects)']);    %% plotting histograms
%     end


% end







function [accuracy, mean_RT_correct, std_RT_correct, std_RT_error, mean_RT_error, mean_dp, dp] = calculate_choices (Ns, Mtype, Gt, difficulty, U, Y)
    % Extract go trials (where visual input = 1)
    go_trials = find(U(1,:) == 1);

    % Initialize arrays for summary stats
    accuracy = zeros(1, Ns);
    mean_RT_correct = zeros(1, Ns);
    std_RT_correct = zeros(1, Ns);

    std_RT_error = zeros(1, Ns);
    mean_RT_error = zeros(1, Ns);

    mean_dp = zeros(1, Ns);
    dp = zeros(Ns, length(go_trials));
    disp('size ')
    disp(size(dp(1))) ;
    disp(numel(dp(1))) ;

    for k = 1:Ns % across participants
        % Calculate accuracy (only on go trials)
        responses = Y{k}(1, go_trials); % get the choice during a go_trial

        % responses(responses == -1) = NaN;  % Exclude no-response trials, no need since we already checked go trials?
        %disp("how many response trials")
        %disp(size(responses(responses ~= -1))) % how many were response trials

        actual_stim = U(2, go_trials);  % 0=standard, 1=deviant
        accuracy(k) = mean(responses == actual_stim, 'omitnan');

        % Calculate mean RT for correct and error trials
        correct_trials = go_trials(responses == actual_stim);
        error_trials = go_trials(responses ~= actual_stim & ~isnan(responses));

        if (Gt == 2); mean_dp = mean(Y{k}(3, go_trials)) ; dp(k, :) = Y{k}(3, go_trials) ; end % if in sdt take third observable dprime
        if (Gt == 4); mean_dp = mean(Y{k}(5, go_trials)) ; dp(k, :) = Y{k}(5, go_trials) ; end  % if in energy sdt take third observable dprime

        if ~isempty(correct_trials)
            mean_RT_correct(k) = mean(Y{k}(2, correct_trials));
            std_RT_correct(k) = std(Y{k}(2, correct_trials)) ;
        end
        if ~isempty(error_trials)
            mean_RT_error(k) = mean(Y{k}(2, error_trials));
            std_RT_error(k) = std(Y{k}(2, error_trials)) ;
        end
    end

    % disp(mean_RT_correct(1, Ns)) ;

    % Display summary
    fprintf('\n=== SIMULATION SUMMARY ===\n');
    fprintf('Model: %s\n', Mtype);
    fprintf('Diffculty level: %s\n', difficulty);
    fprintf('Mean D prime across subjects: %d\n', mean(mean_dp));
    fprintf('Number of subjects: %d\n', Ns);
    fprintf('Mean accuracy: %.2f%% (SD: %.2f%%)\n', ...
        mean(accuracy)*100, std(accuracy)*100);
    fprintf('Mean RT across subjects (correct): %.2f ms (SD: %.2f ms)\n', ...
        mean(mean_RT_correct), std(mean_RT_correct));
    fprintf('Mean RT across subjects (error): %.2f ms (SD: %.2f ms)\n', ...
        mean(mean_RT_error), std(mean_RT_error));

    fprintf('Mean RT 1st subject (correct): %.2f ms (SD: %.2f ms)\n', ...
        (mean_RT_correct(1)), std_RT_correct(1));
    fprintf('Mean RT 1st subject (error): %.2f ms (SD: %.2f ms)\n', ...
        (mean_RT_error(1)), std_RT_error(1));

end


function plot_significance_bar(data1, data2, condition_names, ylabel_text, title_text, varargin)
    % PLOT_SIGNIFICANCE_BAR General purpose function for plotting significance bars
    %
    % Inputs:
    %   data1: First dataset (vector of values)
    %   data2: Second dataset (vector of values)
    %   condition_names: Cell array with two strings, e.g., {'Predictable', 'Unpredictable'}
    %   ylabel_text: String for y-axis label
    %   title_text: String for plot title
    %   varargin: Optional name-value pairs:
    %       'multiplier': Factor to multiply means (e.g., 100 for percentage) (default: 1)
    %       'y_offset_factor': Additional offset for significance text (default: 5)
    %       'font_size_star': Font size for '*' (default: 16)
    %       'font_size_ns': Font size for 'N.S.' (default: 12)
    %       'show_individual_points': Whether to show individual data points (default: false)

    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'multiplier', 1);
    addParameter(p, 'y_offset_factor', 5);
    addParameter(p, 'font_size_star', 16);
    addParameter(p, 'font_size_ns', 12);
    addParameter(p, 'show_individual_points', false);
    parse(p, varargin{:});

    multiplier = p.Results.multiplier;
    y_offset_factor = p.Results.y_offset_factor;
    font_size_star = p.Results.font_size_star;
    font_size_ns = p.Results.font_size_ns;
    show_individual_points = p.Results.show_individual_points;

    % Calculate means and standard deviations
    mean1 = mean(data1) * multiplier;
    mean2 = mean(data2) * multiplier;
    std1 = std(data1) * multiplier;
    std2 = std(data2) * multiplier;

    % Handle the case of single subject
    n_subjects1 = length(data1);
    n_subjects2 = length(data2);

    if n_subjects1 == 1 || n_subjects2 == 1
        warning('One or both conditions have only one subject. Statistical testing requires multiple subjects per condition.');
        p = NaN;
        h = NaN;
        significance_text = 'N.S. (n=1)';
        use_significance = false;
    else
        % Perform t-test for significance
        [h, p] = ttest2(data1, data2);
        % fprintf('P value is : %.3f\n', p);
        % fprintf('h value is : %.3d\n', h);

        if p < 0.05
            significance_text = '*';
            use_significance = true;
        else
            significance_text = 'N.S.';
            use_significance = true;
        end
    end

    % Create bar plot
    X = categorical(condition_names);
    figure;
    bar_handle = bar(X, [mean1, mean2]);
    hold on;

    % Add error bars
    errorbar(1, mean1, std1, 'k.', 'LineWidth', 1.5, 'MarkerSize', 10);
    errorbar(2, mean2, std2, 'k.', 'LineWidth', 1.5, 'MarkerSize', 10);

    % Add individual data points if requested
    if show_individual_points
        % Jitter the x-coordinates slightly to avoid overlap
        jitter1 = (rand(size(data1)) - 0.5) * 0.2;
        jitter2 = (rand(size(data2)) - 0.5) * 0.2;
        scatter(1 + jitter1, data1 * multiplier, 30, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
        scatter(2 + jitter2, data2 * multiplier, 30, 'r', 'filled', 'MarkerFaceAlpha', 0.5);
    end

    % Calculate y-position for significance text
    % Use the maximum of the means plus their standard deviations
    max_height = max([mean1 + std1, mean2 + std2]);

    % Add significance indicator with automatic positioning
    if use_significance
        text_x = 1.5; % Center of the two bars

        % Calculate y position dynamically based on plot limits
        y_limits = ylim;
        y_max_current = y_limits(2);

        % Position text slightly above the highest bar or current y-limit
        if max_height + y_offset_factor > y_max_current
            % Need to extend y-axis
            ylim([0, max_height + y_offset_factor * 1.5]);
            text_y = max_height + y_offset_factor;
        else
            text_y = max_height + y_offset_factor;
        end

        % Add significance text
        if strcmp(significance_text, '*')
            text(text_x, text_y, significance_text, ...
                'HorizontalAlignment', 'center', 'FontSize', font_size_star, ...
                'FontWeight', 'bold');
        else
            text(text_x, text_y, significance_text, ...
                'HorizontalAlignment', 'center', 'FontSize', font_size_ns);
        end
    end

    xlabel(strjoin(condition_names, ' vs '));
    ylabel(ylabel_text);
    title(title_text);

    % Add sample size information to the plot
    text(0.02, 0.98, sprintf('n=%d, %d', n_subjects1, n_subjects2), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontSize', 8, 'Color', 'black');

    hold off;
end
