function [] = calculate_plot_choices(Ns, Mtype, Gt, cases, isAuditory, difficulty)
    % CALCULATE_PLOT_CHOICES Plot behavioral metrics across multiple cases
    model_name = get_model_name(str2num(Mtype(2)) , Gt) ;
    general_description = sprintf('(%s model, n=%d subjects, %s difficulty)', model_name, Ns, difficulty) ;
    % Define metrics to extract and plot
    metrics = [
        struct('name', 'Accuracy', 'field', 'accuracy', ...
        'ylabel', 'Accuracy (%)', 'multiplier', 100, 'show_points', true);
        struct('name', 'Correct RT', 'field', 'mean_RT_correct', ...
        'ylabel', 'Reaction Time (ms)', 'multiplier', 1000, 'show_points', false);
        struct('name', 'Error RT', 'field', 'mean_RT_error', ...
        'ylabel', 'Reaction Time (ms)', 'multiplier', 1000, 'show_points', false);
        struct('name', 'D-prime', 'field', 'mean_dp', ...
        'ylabel', "d' (averaged)", 'multiplier', 1, 'show_points', true)
        ];

    % colors = lines(length(cases));
    colors = [[0, 0.5, 0]; [1, 0.35, 0]; [0.98, 0.85, 0]] ;

    % Only include d-prime if Gt == 2 or Gt == 5 (SDT models)
    if Gt ~= 2 && Gt ~= 5
        metrics = metrics(1:3);
        dp_values = cell(length(cases), 1);
    end

    % Preallocate cell arrays for each metric across cases
    for m = 1:length(metrics)
        metrics(m).data = cell(length(cases), 1);
    end

    % Extract data for each case
    for i = 1:length(cases)
        [accuracy, mean_RT_correct, ~, ~, mean_RT_error, mean_dp , dp] = ...
            calculation_plotting.calculate_choices(Ns, model_name, Gt, difficulty, cases(i).U, cases(i).Y);

        metrics(1).data{i} = accuracy;
        metrics(2).data{i} = mean_RT_correct;
        metrics(3).data{i} = mean_RT_error;
        if Gt == 2 || Gt == 5
            metrics(4).data{i} = mean_dp;
            dp_values{i} = dp ;
        end
    end

    if (Gt == 2 || Gt == 5)

        figure('Name', sprintf('D prime trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                plot(dp_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_amp = mean(dp_values{i}, 1);
            plot(mean_amp, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('D prime', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Sensitvity (d'') - %s ', cases(i).title), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('D prime trajectories'), 'FontSize', 14, 'FontWeight', 'bold');
        subtitle((general_description))
    end

    % Plot each metric
    for m = 1:length(metrics)
        if length(cases) > 1
            figure ;
            hold on;


            all_means = zeros(1, length(cases));
            all_stds = zeros(1, length(cases));
            all_sems = zeros(1, length(cases));  % Standard error of mean

            % Store bar handles for sigstar positioning
            bar_handles = zeros(1, length(cases));

            for i = 1:length(cases)
                data = metrics(m).data{i} * metrics(m).multiplier;
                all_means(i) = mean(data);
                all_stds(i) = std(data);
                all_sems(i) = std(data) / sqrt(length(data));

                % Bar plot
                bar_handles(i) = bar(i, all_means(i), 'FaceColor', colors(i,:), ...
                    'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 1);

                % Add individual subject data points with fainter colors
                if metrics(m).show_points
                    jitter = (rand(size(data)) - 0.5) * 0.2;
                    scatter(i + jitter, data, 40, colors(i,:), ...
                        'filled', 'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.4);
                else
                    % For RT data, plot individual means with fainter lines
                    for subj = 1:length(data)
                        h = plot(i + (rand-0.5)*0.15, data(subj), 'o', ...
                            'Color', colors(i, :), 'MarkerSize', 8, ...
                            'MarkerFaceColor', colors(i, :));
                        % disp([colors(i,:), 0.3]) ;
                        h.Color(4) = 0.5; % Set 50% transparency

                    end
                end
            end

            % Add error bars (using SEM)
            errorbar(1:length(cases), all_means, all_sems, 'k.', ...
                'LineWidth', 1.5, 'MarkerSize', 12, 'CapSize', 10);

            % Add significance testing with sigstar
            if Ns > 1
                % Calculate all pairwise p-values
                p_values = ones(length(cases));
                significant_pairs = {};
                pair_counter = 1;
                sig_p_values = [];

                for i = 1:length(cases)-1
                    for j = i+1:length(cases)
                        % [~, p] = ttest2(metrics(m).data{i}, metrics(m).data{j}); % assumes different subjects across groups
                        [h, p] = ttest(metrics(m).data{i}, metrics(m).data{j}); % for same subjects across different groups
                        p_values(i,j) = p;
                        p_values(j,i) = p;

                        % Only add significant pairs (p < 0.05)
                        if p < 0.05
                            significant_pairs{pair_counter} = [i, j];
                            sig_p_values(pair_counter) = p;
                            pair_counter = pair_counter + 1;
                        end
                    end
                end

                % Apply sigstar to significant pairs only
                if ~isempty(significant_pairs)

                    % pairs_mat = cell2mat(significant_pairs);

                    sigstar(significant_pairs, sig_p_values, 1); % version 1

                    % sigstar(significant_pairs, sig_p_values(sub2ind(size(sig_p_values), ...
                    %     cellfun(@(x) x(1), significant_pairs), ...
                    %     cellfun(@(x) x(2), significant_pairs))));

                    % Calculate appropriate y-positions for significance bars
                    % max_vals = all_means + all_sems;
                    % y_max = max(max_vals);
                    % y_range = range(max_vals);

                    % % Adjust significance bar heights
                    % for k = 1:length(significant_pairs)
                    %     if k == 1
                    %         sigstar(significant_pairs(k), sig_p_values(k));
                    %         % else
                    %         %     sigstar(significant_pairs(k), sig_p_values(k));
                    %     end
                    % end
                end
            end

            % Formatting
            xlabel('Condition', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(metrics(m).ylabel, 'FontSize', 12, 'FontWeight', 'bold');


            title(sprintf('Mean %s ', ...
                metrics(m).name), ...
                'FontSize', 14, 'FontWeight', 'bold');
            subtitle(general_description) ;

            % Set x-axis labels
            set(gca, 'XTick', 1:length(cases), 'XTickLabel', {cases.title}, ...
                'FontSize', 11, 'FontWeight', 'bold');

            % Improve grid and box appearance
            grid on;
            set(gca, 'GridAlpha', 0.3, 'Box', 'off');

            hold off;


        end
    end

    export_for_R = false ;

    % Add at the end of your function:
    if export_for_R
        output_dir = fullfile(pwd, 'R_analysis_data');
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        calculation_plotting.export_for_R_analysis(Ns, Mtype, Gt, cases, difficulty, output_dir, metrics);
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


