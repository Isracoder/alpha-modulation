function [] = calculate_plot_neural(Ns, Mtype, Gt, cases, neuralInd, isAuditory, difficulty)
    % Plot neural data across multiple cases
    model_name = get_model_name(str2num(Mtype(2)) , Gt) ;
    general_description = sprintf('(%s model, n=%d subjects, %s difficulty)', model_name, Ns, difficulty) ;
    right_bound = 1:size(cases(1).Y{1}, 2);
    colors = [[0, 0.5, 0]; [1, 0.35, 0]; [0.98, 0.85, 0]] ;

    if (isAuditory)
        % Preallocate cell arrays for all cases
        % colors = lines(length(cases));
        alpha_amp_values = cell(length(cases), 1);
        alpha_phase_values = cell(length(cases), 1);
        isi_values = cell(length(cases), 1);
        modified_amp = cell(length(cases), 1);

        % Extract data for each case
        for i = 1:length(cases)
            % Extract all subjects' data
            alpha_amp_values{i} = cell2mat(cellfun(@(x) x(neuralInd, right_bound)', ...
                cases(i).Y, 'UniformOutput', false))';
            alpha_phase_values{i} = cell2mat(cellfun(@(x) x(neuralInd + 1, right_bound)', ...
                cases(i).Y, 'UniformOutput', false))';
            isi_values{i} = cases(i).U(3, right_bound);
            if (Gt == 2 || Gt == 5)
                modified_amp{i} = cell2mat(cellfun(@(x) x(7, right_bound)', ...
                    cases(i).Y, 'UniformOutput', false))';
            end
        end

        % Plot ISI values with individual subjects
        figure('Name', sprintf('ISI values - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot mean as thick dark line
            mean_isi = mean(isi_values{i}, 1);
            plot(mean_isi, 'Color', colors(i,:), 'LineWidth', 1);

            ylabel('ISI values', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('ISI values - %s', cases(i).title), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('ISI trajectories'), 'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;

        % Plot amplitude trajectories with individual subjects
        figure('Name', sprintf('Amplitude trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                plot(alpha_amp_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_amp = mean(alpha_amp_values{i}, 1);
            plot(mean_amp, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Amplitude (a.u.)', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Alpha Amplitude - %s', cases(i).title, Ns), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Amplitude trajectories'), 'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;


        compPlot = figure('Name', 'Amplitude Comparison');
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            plot(ax1, mean(alpha_amp_values{i}, 1), 'Color', colors(i,:), 'LineWidth', 1.3);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        xlabel('Trial');
        ylabel('Amplitude');
        title(ax1, 'Amplitude Comparison');
        legend(cases.title);

        % Plot phase trajectories with individual subjects
        figure('Name', sprintf('Phase trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faintt lines
            for subj = 1:Ns
                plot(alpha_phase_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_phase = mean(alpha_phase_values{i}, 1);
            plot(mean_phase, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Phase (rad)', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);

            phaseTitle = sprintf('Phase - %s', cases(i).title);
            if (Gt == 3)
                phaseTitle = sprintf('Delta Phase (2πf·(ISI-μ)) - %s', cases(i).title);
            end
            title(phaseTitle, 'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Phase trajectories'), 'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;

        % Plot phase trajectories with individual subjects
        figure('Name', sprintf('Phase term - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % ((1 - cos(2* pi* (input_delta) / T)) / 2 )
            % Plot individual subjects as faint lines
            for subj = 1:Ns
                plot((1 - cos(alpha_phase_values{i}(subj, :) ./100)) ./2, 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_phase = mean((1 - cos(alpha_phase_values{i} ./100)) ./2 , 1);
            plot(mean_phase, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Phase (rad)', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);

            phaseTitle = sprintf('Phase - %s', cases(i).title);
            if (Gt == 3)
                phaseTitle = sprintf('Phase term ((1 - cos(delta)) / 2) - %s', cases(i).title);
            end
            title(phaseTitle, 'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Phase trajectories'), 'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;

        % Compare amplitudes across cases with significance testing
        figure('Name', 'Amplitude Comparison Across Conditions');
        hold on;

        % Calculate means and SEMs for each case
        case_means = zeros(1, length(cases));
        case_sems = zeros(1, length(cases));

        for i = 1:length(cases)
            % Average across trials for each subject, then across subjects
            subj_means = mean(alpha_amp_values{i}, 2);
            case_means(i) = mean(subj_means);
            case_sems(i) = std(subj_means) / sqrt(Ns);

            % Bar plot
            bar(i, case_means(i), 'FaceColor', colors(i,:), ...
                'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 1);

            % Individual subject points
            jitter = (rand(Ns,1) - 0.5) * 0.2;
            scatter(i + jitter, subj_means, 40, colors(i,:), ...
                'filled', 'MarkerFaceAlpha', 0.4);
        end

        % Add error bars
        errorbar(1:length(cases), case_means, case_sems, 'k.', ...
            'LineWidth', 1.5, 'MarkerSize', 12, 'CapSize', 10);

        % Significance testing with sigstar
        if Ns > 1 && length(cases) > 1
            significant_pairs = {};
            sig_p_values = [];
            pair_counter = 1;

            % Get maximum y-value for positioning
            max_vals = case_means + case_sems;
            y_max = max(max_vals);
            y_range = range(max_vals);
            base_ypos = y_max + 0.05 * y_range;

            for i = 1:length(cases)-1
                for j = i+1:length(cases)
                    subj_means_i = mean(alpha_amp_values{i}, 2);
                    subj_means_j = mean(alpha_amp_values{j}, 2);
                    [~, p] = ttest2(subj_means_i, subj_means_j);

                    if p < 0.05
                        significant_pairs{pair_counter} = [i, j];
                        sig_p_values(pair_counter) = p;
                        pair_counter = pair_counter + 1;
                    end
                end
            end

            if ~isempty(significant_pairs)
                % Convert cell array to matrix for sigstar
                % pairs_mat = cell2mat(significant_pairs);

                sigstar(significant_pairs, sig_p_values, 1); % version 1
                % Try different sigstar syntaxes
                % if exist('sigstar', 'file') == 2
                % try

                % catch
                %     try

                %         if length(significant_pairs) == 1
                %             sigstar(pairs_mat, sig_p_values, 'ypos', base_ypos);
                %         else
                %             % For multiple pairs, stack them
                %             for k = 1:length(significant_pairs)
                %                 ypos = base_ypos + (0.03 * (k-1)) * y_range;
                %                 sigstar(pairs_mat(k,:), sig_p_values(k), 'ypos', ypos);
                %             end
                %         end
                %     catch
                %         % Version 3: Simple call without position
                %         sigstar(pairs_mat, sig_p_values);
                %     end
                % end
                % else
                %     warning('sigstar not found. Skipping significance markers.');
                % end
            end

        end

        xlabel('Condition', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Mean Amplitude (a.u.)', 'FontSize', 12, 'FontWeight', 'bold');
        set(gca, 'XTick', 1:length(cases), 'XTickLabel', {cases.title}, ...
            'FontSize', 11, 'FontWeight', 'bold');
        title(sprintf('Amplitude comparison'), 'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;
        grid on;
        hold off;

        % Plot modified amplitude for SDT models
        if (Gt == 2 || Gt == 5) && ~isempty(modified_amp{1})
            figure('Name', sprintf('Modified Amplitude trajectories - %s model', model_name));
            for i = 1:length(cases)
                subplot(length(cases), 1, i);
                hold on;

                % Plot individual subjects as faint lines
                for subj = 1:Ns
                    plot(modified_amp{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                        'LineWidth', 0.8);
                end

                % Plot mean as thick dark line
                mean_amp = mean(modified_amp{i}, 1);
                plot(mean_amp, 'Color', colors(i,:), 'LineWidth' , 1.8);

                ylabel('Alternative Amplitude (a.u.)', 'FontSize', 10);
                xlabel('Trial', 'FontSize', 10);
                title(sprintf('Modified amplitude calculation - %s (n=%d subjects)', cases(i).title, Ns), ...
                    'FontSize', 11, 'FontWeight', 'bold');
                grid on;
                hold off;
            end
            sgtitle(sprintf('Modified Amplitude trajectories'), 'FontSize', 14, 'FontWeight', 'bold');
            subtitle(general_description) ;

            figure('Name', 'Modified Amplitude Comparison');
            hold on;

            modified_means = zeros(1, length(cases));
            modified_sems = zeros(1, length(cases));

            for i = 1:length(cases)
                subj_means = mean(modified_amp{i}, 2);
                modified_means(i) = mean(subj_means);
                modified_sems(i) = std(subj_means) / sqrt(Ns);

                bar(i, modified_means(i), 'FaceColor', colors(i,:), ...
                    'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 1);

                jitter = (rand(Ns,1) - 0.5) * 0.2;
                scatter(i + jitter, subj_means, 40, colors(i,:), ...
                    'filled', 'MarkerFaceAlpha', 0.4);
            end

            errorbar(1:length(cases), modified_means, modified_sems, 'k.', ...
                'LineWidth', 1.5, 'MarkerSize', 12, 'CapSize', 10);

            xlabel('Condition', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Modified Amplitude (a.u.)', 'FontSize', 12, 'FontWeight', 'bold');
            set(gca, 'XTick', 1:length(cases), 'XTickLabel', {cases.title}, ...
                'FontSize', 11, 'FontWeight', 'bold');
            title(sprintf('Modified amplitude'), ...
                'FontSize', 14, 'FontWeight', 'bold');
            subtitle(general_description) ;
            grid on;
            hold off;
        end

    else
        % Visual case: bilateral amplitude (left & right)
        idx_left = neuralInd(1);
        idx_right = neuralInd(2);

        % Extract left and right amplitudes for each case
        left_amp_values = cell(length(cases), 1);
        right_amp_values = cell(length(cases), 1);
        left_phase_values = cell(length(cases), 1);
        right_phase_values = cell(length(cases), 1);
        location_values = cell(length(cases), 1);

        for i = 1:length(cases)
            left_amp_values{i} = cell2mat(cellfun(@(x) x(idx_left, right_bound)', ...
                cases(i).Y, 'UniformOutput', false))';
            right_amp_values{i} = cell2mat(cellfun(@(x) x(idx_right, right_bound)', ...
                cases(i).Y, 'UniformOutput', false))';
            left_phase_values{i} = cell2mat(cellfun(@(x) x(idx_left + 2, right_bound)', ...
                cases(i).Y, 'UniformOutput', false))';
            right_phase_values{i} = cell2mat(cellfun(@(x) x(idx_right + 2, right_bound)', ...
                cases(i).Y, 'UniformOutput', false))';
            location_values{i} = cases(i).U(4, right_bound);
        end



        % Plot left amplitudes with individual subjects
        figure('Name', 'Left Hemisphere Amplitudes');
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            for subj = 1:Ns
                plot(left_amp_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            mean_left = mean(left_amp_values{i}, 1);
            plot(mean_left, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Amplitude (µV)', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Left hemisphere - %s', ...
                cases(i).title), 'FontSize', 11, 'FontWeight', 'bold');

            grid on;
            hold off;
        end
        sgtitle(sprintf('Left Alpha Amplitude - %s model', model_name), ...
            'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;

        % Plot right amplitudes with individual subjects
        figure('Name', 'Right Hemisphere Amplitudes');
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            for subj = 1:Ns
                plot(right_amp_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            mean_right = mean(right_amp_values{i}, 1);
            plot(mean_right, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Amplitude (µV)', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Right hemisphere - %s', ...
                cases(i).title, Ns), 'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Right Alpha Amplitude - %s model', model_name), ...
            'FontSize', 14, 'FontWeight', 'bold');
        subtitle(general_description) ;

        % Compare left vs right amplitudes within each case
        for i = 1:length(cases)
            figure('Name', sprintf('Lateralization - %s', cases(i).title));
            hold on;

            % Calculate means for left and right
            left_means = mean(left_amp_values{i}, 2);
            right_means = mean(right_amp_values{i}, 2);

            % Bar plot
            bar_data = [mean(left_means), mean(right_means)];
            bar_handles = bar(1:2, bar_data, 'FaceAlpha', 0.6);
            bar_handles(1).FaceColor = [0, 0.4470, 0.7410];
            bar_handles(2).FaceColor = [0.8500, 0.3250, 0.0980];

            % Individual subject points
            jitter_left = (rand(Ns,1) - 0.5) * 0.2;
            jitter_right = (rand(Ns,1) - 0.5) * 0.2;
            scatter(1 + jitter_left, left_means, 40, 'b', ...
                'filled', 'MarkerFaceAlpha', 0.4);
            scatter(2 + jitter_right, right_means, 40, 'r', ...
                'filled', 'MarkerFaceAlpha', 0.4);

            % Error bars
            errorbar(1:2, bar_data, [std(left_means)/sqrt(Ns), std(right_means)/sqrt(Ns)], ...
                'k.', 'LineWidth', 1.5, 'MarkerSize', 12, 'CapSize', 10);

            % Significance test
            if Ns > 1
                [~, p] = ttest(left_means, right_means);
                if p < 0.05
                    y_max = max(bar_data + [std(left_means)/sqrt(Ns), std(right_means)/sqrt(Ns)]);
                    sigstar({[1, 2]}, p, 'ypos', y_max + 0.05 * y_max);
                end
            end

            set(gca, 'XTick', 1:2, 'XTickLabel', {'Left', 'Right'}, ...
                'FontSize', 11, 'FontWeight', 'bold');
            ylabel('Mean Amplitude (µV)', 'FontSize', 12, 'FontWeight', 'bold');
            title(sprintf('Hemisphere comparison - %s', ...
                cases(i).title), 'FontSize', 13, 'FontWeight', 'bold');
            subtitle(general_description) ;
            grid on;
            hold off;
        end
    end
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
% title(sprintf('Left hemisphere alpha amplitude across conditions, model %s/G%d', model_name, Gt));
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
% title(sprintf('Right hemisphere alpha amplitude across conditions, model %s/G%d', model_name, Gt));
% legend(cases.title);

% % Histograms: left amplitudes across cases
% figure('Name', 'Left Amplitude Histogram');
% for i = 1:length(cases)
%     histogram(left_amp_values{i}{1}, 'NumBins', 15, 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
%     hold on;
% end
% hold off;
% title(sprintf('Left amplitude distribution, model %s/G%d', model_name, Gt));
% legend(cases.title);

% % Histograms: right amplitudes across cases
% figure('Name', 'Right Amplitude Histogram');
% for i = 1:length(cases)
%     histogram(right_amp_values{i}{1}, 'NumBins', 15, 'FaceColor', colors(i,:), 'FaceAlpha', 0.6);
%     hold on;
% end
% hold off;
% title(sprintf('Right amplitude distribution, model %s/G%d', model_name, Gt));
% legend(cases.title);

% function [] = calculate_plot_neural(Ns, model_name, Gt,  U1, Y1, U2, Y2, ind)

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

