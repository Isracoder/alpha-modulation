function [] = calculate_choice_repeated(Ns, Mtype, Gt, cases, isAuditory, difficulty)
    % CALCULATE_CHOICE_REPEATED Plot behavioral metrics for repeated-measures design
    %   Same subjects across all conditions, with proper statistical testing
    model_name = get_model_name(str2num(Mtype(2)) , Gt) ;
    % Define metrics to extract and plot
    metrics = [
        struct('name', 'Accuracy', 'field', 'accuracy', ...
        'ylabel', 'Accuracy (%)', 'multiplier', 100, 'show_points', true);
        struct('name', 'Correct RT', 'field', 'mean_RT_correct', ...
        'ylabel', 'Reaction Time (ms)', 'multiplier', 1, 'show_points', false);
        struct('name', 'Error RT', 'field', 'mean_RT_error', ...
        'ylabel', 'Reaction Time (ms)', 'multiplier', 1, 'show_points', false);
        struct('name', 'D-prime', 'field', 'mean_dp', ...
        'ylabel', "d' (averaged)", 'multiplier', 1, 'show_points', true)
        ];

    % Only include d-prime if Gt == 2 or Gt == 5 (SDT models)
    if Gt ~= 2 && Gt ~= 5
        metrics = metrics(1:3);
    end

    % Preallocate cell arrays for each metric across cases
    for m = 1:length(metrics)
        metrics(m).data = cell(length(cases), 1);
    end

    % Extract data for each case
    for i = 1:length(cases)
        [accuracy, mean_RT_correct, ~, ~, mean_RT_error, mean_dp] = ...
            calculation_plotting.calculate_choices(Ns, model_name, Gt, difficulty, cases(i).U, cases(i).Y);

        metrics(1).data{i} = accuracy;
        metrics(2).data{i} = mean_RT_correct;
        metrics(3).data{i} = mean_RT_error;
        if Gt == 2 || Gt == 5
            metrics(4).data{i} = mean_dp;
        end
    end

    % Plot each metric
    for m = 1:length(metrics)
        if length(cases) > 1
            % Organize data: subjects × conditions
            nSubjects = Ns;
            nConditions = length(cases);
            data_matrix = zeros(nSubjects, nConditions);

            for i = 1:nConditions
                data_matrix(:, i) = metrics(m).data{i} * metrics(m).multiplier;
            end

            % 1. Repeated-measures ANOVA
            [p_rm, F, df1, df2] = repeated_measures_anova(data_matrix);

            % 2. Post-hoc: paired t-tests with correction
            [sig_pairs, sig_p_values] = posthoc_paired_ttest_corrected(data_matrix);

            % 3. Within-subject error bars (Loftus & Masson, 1994)
            [means, within_subject_sem] = within_subject_errorbars(data_matrix);

            % Create figure
            figure();
            hold on;

            % Color palette (professional, colorblind-friendly)
            colors = [
                0.2, 0.4, 0.8;   % Blue
                0.8, 0.3, 0.3;   % Red
                0.2, 0.7, 0.4;   % Green
                0.8, 0.6, 0.2;   % Orange
                0.6, 0.3, 0.7;   % Purple
                0.3, 0.7, 0.7;   % Teal
                ];

            % Plot bars
            bar_handles = zeros(1, nConditions);
            for i = 1:nConditions
                bar_handles(i) = bar(i, means(i), 'FaceColor', colors(i, :), ...
                    'FaceAlpha', 0.7, 'EdgeColor', 'k', 'LineWidth', 1.2);
            end

            % Add individual subject data points (connected lines for repeated measures)
            if metrics(m).show_points
                % Plot lines connecting same subject across conditions
                for subj = 1:nSubjects
                    plot(1:nConditions, data_matrix(subj, :), 'o-', ...
                        'Color', [0.5, 0.5, 0.5, 0.3], ...
                        'MarkerSize', 6, 'MarkerFaceColor', [0.5, 0.5, 0.5], ...
                        'LineWidth', 0.8);
                end
            else
                % For RT data, plot individual points with transparency
                for subj = 1:nSubjects
                    for cond = 1:nConditions
                        plot(cond + (rand - 0.5) * 0.15, data_matrix(subj, cond), 'o', ...
                            'Color', [colors(cond, :), 0.4], ...
                            'MarkerSize', 8, 'MarkerFaceColor', colors(cond, :));
                    end
                end
            end

            % Add within-subject error bars
            errorbar(1:nConditions, means, within_subject_sem, 'k.', ...
                'LineWidth', 1.5, 'MarkerSize', 12, 'CapSize', 10);

            % Add significance bars using sigstar
            if ~isempty(sig_pairs)
                % Calculate y-positions for significance bars
                max_vals = means + within_subject_sem;
                y_max = max(max_vals);
                y_range = range(max_vals);

                % Call sigstar with significant pairs
                sigstar(sig_pairs, sig_p_values);
            end

            % Formatting
            xlabel('Condition', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(metrics(m).ylabel, 'FontSize', 12, 'FontWeight', 'bold');

            % Add ANOVA results to title
            if p_rm < 0.001
                p_text = sprintf('p < 0.001');
            else
                p_text = sprintf('p = %.4f', p_rm);
            end

            title(sprintf('Mean %s (model= %s, n=%d subjects, %s difficulty)\nRM ANOVA: F(%d,%d)=%.2f, %s', ...
                metrics(m).name, model_name,  Ns, difficulty, df1, df2, F, p_text), ...
                'FontSize', 12, 'FontWeight', 'normal');

            % Set x-axis labels
            set(gca, 'XTick', 1:nConditions, 'XTickLabel', {cases.title}, ...
                'FontSize', 11, 'FontWeight', 'bold', 'Box', 'off');

            % Add grid and improve appearance
            grid on;
            set(gca, 'GridAlpha', 0.2, 'Box', 'off');

            % Adjust y-limits to accommodate significance bars
            ylim([0, max(ylim) * 1.15]);

            hold off;
        end
    end
end

% =========================================================================
% STATISTICAL FUNCTIONS
% =========================================================================

function [p, F, df1, df2] = repeated_measures_anova(data)
    % REPEATED_MEASURES_ANOVA One-way repeated-measures ANOVA
    %   data: subjects × conditions matrix

    [nSubjects, nConditions] = size(data);

    % Compute sums of squares
    grand_mean = mean(data(:));
    subject_means = mean(data, 2);
    condition_means = mean(data, 1);

    SS_total = sum((data(:) - grand_mean).^2);
    SS_subjects = nConditions * sum((subject_means - grand_mean).^2);
    SS_conditions = nSubjects * sum((condition_means - grand_mean).^2);
    SS_error = SS_total - SS_subjects - SS_conditions;

    % Degrees of freedom
    df1 = nConditions - 1;
    df2 = (nSubjects - 1) * (nConditions - 1);

    % Mean squares
    MS_conditions = SS_conditions / df1;
    MS_error = SS_error / df2;

    % F-statistic and p-value
    F = MS_conditions / MS_error;
    p = 1 - fcdf(F, df1, df2);
end


function [sig_pairs, sig_p_values] = posthoc_paired_ttest_corrected(data)
    % POSTHOC_PAIRED_TTEST_CORRECTED Bonferroni-corrected paired t-tests
    %   Returns cell array of significant pairs and their corrected p-values
    %   for use with sigstar

    nConditions = size(data, 2);
    pairs = {};
    p_raw = [];
    counter = 1;

    % Perform all pairwise paired t-tests
    for i = 1:nConditions-1
        for j = i+1:nConditions
            [~, p] = ttest(data(:, i), data(:, j));
            pairs{counter} = [i, j];
            p_raw(counter) = p;
            counter = counter + 1;
        end
    end

    % Bonferroni correction
    n_comparisons = length(pairs);
    p_corrected = min(p_raw * n_comparisons, 1);

    % Keep only significant pairs (p < 0.05)
    sig_mask = p_corrected < 0.05;
    sig_pairs = pairs(sig_mask);
    sig_p_values = p_corrected(sig_mask);
end


function [means, within_sem] = within_subject_errorbars(data)
    % WITHIN_SUBJECT_ERRORBARS Loftus & Masson (1994) within-subject error bars
    %   Removes between-subject variance for proper within-subject visualization

    nSubjects = size(data, 1);
    subject_means = mean(data, 2);
    data_normalized = data - subject_means + mean(data(:));
    within_sem = std(data_normalized) / sqrt(nSubjects);
    means = mean(data);
end



% function [accuracy, mean_RT_correct, std_RT_correct, std_RT_error, mean_RT_error, mean_dp, dp] = calculate_choices(Ns, model_name, Gt, difficulty, U, Y)
%     % Extract go trials (where visual input = 1)
%     go_trials = find(U(1,:) == 1);

%     % Initialize arrays for summary stats
%     accuracy = zeros(1, Ns);
%     mean_RT_correct = zeros(1, Ns);
%     std_RT_correct = zeros(1, Ns);
%     std_RT_error = zeros(1, Ns);
%     mean_RT_error = zeros(1, Ns);
%     mean_dp = zeros(1, Ns);
%     dp = zeros(Ns, length(go_trials));

%     for k = 1:Ns % across participants
%         responses = Y{k}(1, go_trials);
%         actual_stim = U(2, go_trials);
%         accuracy(k) = mean(responses == actual_stim, 'omitnan');

%         % Calculate mean RT for correct and error trials
%         correct_trials = go_trials(responses == actual_stim);
%         error_trials = go_trials(responses ~= actual_stim & ~isnan(responses));

%         if (Gt == 2); mean_dp = mean(Y{k}(3, go_trials)); dp(k, :) = Y{k}(3, go_trials); end
%         if (Gt == 5); mean_dp = mean(Y{k}(5, go_trials)); dp(k, :) = Y{k}(5, go_trials); end

%         if ~isempty(correct_trials)
%             mean_RT_correct(k) = mean(Y{k}(2, correct_trials));
%             std_RT_correct(k) = std(Y{k}(2, correct_trials));
%         end
%         if ~isempty(error_trials)
%             mean_RT_error(k) = mean(Y{k}(2, error_trials));
%             std_RT_error(k) = std(Y{k}(2, error_trials));
%         end
%     end

%     % Display summary
%     fprintf('\n=== SIMULATION SUMMARY ===\n');
%     fprintf('Model: %s\n', model_name);
%     fprintf('Difficulty level: %s\n', difficulty);
%     fprintf('Mean D prime across subjects: %.3f\n', mean(mean_dp));
%     fprintf('Number of subjects: %d\n', Ns);
%     fprintf('Mean accuracy: %.2f%% (SD: %.2f%%)\n', mean(accuracy)*100, std(accuracy)*100);
%     fprintf('Mean RT across subjects (correct): %.2f ms (SD: %.2f ms)\n', mean(mean_RT_correct), std(mean_RT_correct));
%     fprintf('Mean RT across subjects (error): %.2f ms (SD: %.2f ms)\n', mean(mean_RT_error), std(mean_RT_error));
% end