function [] = calculate_plot_precision(Ns, Mtype, Gt, cases, isAuditory, difficulty) % to do convert this file to include case system for dynamic and expandable inputs
    % simulParam has ns subjects, for each has x vector

    model_name = get_model_name(str2num(Mtype(2)) , Gt) ;

    right_bound = 1:size(cases(1).SimulParam(1).x, 2);
    num_values = size(cases(1).SimulParam(1).x, 1) ;
    fprintf('Number of trials: %d %%\n' , size(cases(1).SimulParam(1).x, 2)) ;


    if (isAuditory)

        % Preallocate cell arrays for all cases
        colors = lines(length(cases));
        pred_precision_values = cell(length(cases), 1);
        posterior_precision_values  = cell(length(cases), 1);
        px_values  = cell(length(cases), 1);
        alpha_values  = cell(length(cases), 1);
        beta_values  = cell(length(cases), 1);
        prediction_errors = cell(length(cases) , 1) ;
        power_values = cell(length(cases) , 1) ;




        % Extract data for each case
        for i = 1:length(cases)
            % Extract all subjects' data

            simulParam = cases(i).SimulParam ;
            posterior_precision_values{i} = cell2mat(arrayfun(@(s) exp(s.x(2, right_bound)'), ...
                simulParam, 'UniformOutput', false))' ;
            pred_precision_values{i} = cell2mat(arrayfun(@(s) exp(s.x(5, right_bound)'), ...
                simulParam, 'UniformOutput', false))' ;

            % x_values{i} = cell2mat(arrayfun(@(s) (s.x(11, :)'), ...
            %     simulParam, 'UniformOutput', false))' ;

            power_values{i} = cell2mat(arrayfun(@(s) (s.phi(1)'), ... % first value in phi is the power param
                simulParam, 'UniformOutput', false))' ;

            prediction_errors{i} = cell2mat(arrayfun(@(s) (s.x(1, right_bound)'), ...
                simulParam, 'UniformOutput', false))' - cases(i).U(3, right_bound) ; % difference between expected and actual, positive if actual was before expected, negative if it was late ;


            if (Mtype == "M3" && num_values >= 8)
                alpha_values{i} = cell2mat(arrayfun(@(s) exp(s.x(7, right_bound)'), ...
                    simulParam, 'UniformOutput', false))' ;
                beta_values{i} = cell2mat(arrayfun(@(s) exp(s.x(8, right_bound)'), ...
                    simulParam, 'UniformOutput', false))' ;
                px_values{i} = (alpha_values{i}) ./ (beta_values{i} + eps ) ;

            end

        end

        compPlot = figure('Name', sprintf('Predictive Precision Comparison'));
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            plot(ax1, mean(pred_precision_values{i}, 1), 'Color', colors(i,:), 'LineWidth', 1.3);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        xlabel('Trial');
        set(ax1, 'FontSize', 14)
        ylabel('Predictive Precision');
        title(ax1,  sprintf('Predictive Precision Comparison - %s model', model_name) , 'FontSize' , 14);
        legend(cases.title);

        figure('Name', sprintf('Predictive Precision trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                plot(pred_precision_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_ = mean(pred_precision_values{i}, 1);
            plot(mean_, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Predictive precision', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Predictive precision power - %s (n=%d subjects)', cases(i).title, Ns), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Predictive precision - %s model,  %s difficulty', ...
            model_name, difficulty), 'FontSize', 14, 'FontWeight', 'bold');

        % calculation of entropy
        figure('Name', sprintf('Entropy trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                entropy_values = 0.5 *  log(2 * pi * exp(1) ./ pred_precision_values{i}(subj, :));

                plot(entropy_values, 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_ = mean((0.5 *  log(2 * pi * exp(1) ./ pred_precision_values{i})) , 1);
            plot(mean_, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Entropy', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Entropy - %s (n=%d subjects)', cases(i).title, Ns), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Entropy - %s model,  %s difficulty', ...
            model_name, difficulty), 'FontSize', 14, 'FontWeight', 'bold');


        % calculation of a max
        kappa = -1 ;

        figure('Name', sprintf('A max trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                entropy_values = 0.5 .*  log((2 * pi * exp(1)) ./ pred_precision_values{i}(subj, :));
                a_max = power_values{i}(subj) .* exp (-1 .* entropy_values) ;
                plot(a_max, 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_ = mean(power_values{i} .* exp (kappa .* (0.5 .*  log((2 * pi * exp(1)) ./ pred_precision_values{i}))) , 1);
            plot(mean_, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('A max', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('A max - %s (n=%d subjects)', cases(i).title, Ns), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('A max - %s model,  %s difficulty', ...
            model_name, difficulty), 'FontSize', 14, 'FontWeight', 'bold');


        compPlot = figure('Name', 'Max Amplitude Value Comparison');
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            plot(ax1, mean(power_values{i} .* exp (kappa .* (0.5 *  log(2 * pi * exp(1) ./ pred_precision_values{i}))) , 1), 'Color', colors(i,:), 'LineWidth', 1.3);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        set(ax1, 'FontSize', 14)
        xlabel('Trial');
        ylabel('Amplitude');
        title(ax1, 'Max amp. Value ', 'FontSize' , 14);
        legend(cases.title);

        compPlot = figure('Name', 'Max Amplitude Value Comparison - Division');
        ax1 = axes('Parent', compPlot);
        for i = 1:length(cases)
            plot(ax1, mean(power_values{i} ./  (0.5 *  log(2 * pi * exp(1) ./ pred_precision_values{i})) , 1), 'Color', colors(i,:), 'LineWidth', 1.3);
            hold(ax1, 'on');
        end
        hold(ax1, 'off');
        xlabel('Trial');
        set(gca, 'FontSize', 14)
        ylabel('Amplitude');
        title(ax1, 'Max amp. Value ', 'FontSize' , 14);
        legend(cases.title);


        % prediction error


        figure('Name', sprintf('Prediction error (exp-actual) trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                plot( prediction_errors{i}(subj), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_ = mean( prediction_errors{i} , 1);
            plot(mean_, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('PE (exp-actual)', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Prediction error (exp-actual) - %s (n=%d subjects)', cases(i).title, Ns), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Prediction error (exp-actual) - %s model,  %s difficulty', ...
            model_name, difficulty), 'FontSize', 14, 'FontWeight', 'bold');


        figure('Name', sprintf('Posterior Precision trajectories - %s model', model_name));
        for i = 1:length(cases)
            subplot(length(cases), 1, i);
            hold on;

            % Plot individual subjects as faint lines
            for subj = 1:Ns
                plot(posterior_precision_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                    'LineWidth', 0.8);
            end

            % Plot mean as thick dark line
            mean_ = mean(posterior_precision_values{i}, 1);
            plot(mean_, 'Color', colors(i,:), 'LineWidth' , 1.8);

            ylabel('Posterior precision', 'FontSize', 10);
            xlabel('Trial', 'FontSize', 10);
            title(sprintf('Posterior precision power - %s (n=%d subjects)', cases(i).title, Ns), ...
                'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            hold off;
        end
        sgtitle(sprintf('Posterior precision - %s model, %s difficulty', ...
            model_name, difficulty), 'FontSize', 14, 'FontWeight', 'bold');


        % figure ;
        % h = histogram(post_precision_values_PP , 15);  %
        % h.FaceColor = [0.2 0.6 0.8];  % Set bar color
        % title(['Predictive precision values histogram with model ' Mtype ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

        % figure;
        % plot(pred_precision_values_PP_time, 'LineWidth',0.8)
        % xlabel('Trials')
        % ylabel('Predictive Precision')
        % title(['Predictive precision values across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{PP}' ]);


        % figure ;
        % h = histogram(post_precision_values_UP , 15);  %
        % h.FaceColor = [0.2 0.6 0.8];  % Set bar color
        % title(['Predictive precision values histogram with model ' Mtype  ' and ' num2str(Ns) ' subjects for case UP' ]);    %% plotting histograms


        % figure;
        % plot(pred_precision_values, 'LineWidth',0.8)
        % xlabel('Trials')
        % ylabel('Predictive Precision')
        % title(['Predictive precision values across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{UP}' ]);


        % compPlot = figure('Name', 'PP/UP precision');
        % ax1 = axes('Parent', compPlot);
        % plot(ax1, pred_precision_values_PP_time, 'Color', 'blue');
        % hold(ax1, 'on');
        % plot(pred_precision_values, 'Color', 'red');
        % hold(ax1, 'off');
        % title(ax1, 'PP vs UP predictive precision');
        % legend('PP', 'UP');

        % compPlot = figure('Name', 'PP/UP posterior');
        % ax1 = axes('Parent', compPlot);
        % plot(ax1, posterior_precision_values_PP, 'Color', 'blue');
        % hold(ax1, 'on');
        % plot(posterior_precision_values, 'Color', 'red');
        % hold(ax1, 'off');
        % title(ax1, 'PP vs UP posterior precision');
        % legend('PP', 'UP');


        if (num_values >= 8)
            if (Mtype == "M3")




            elseif (Mtype == "M7")
                % px_PP = exp(x1(8, :)) ;
                % px_UP = exp(x2(8, :)) ;

            else
                return
            end

            figure('Name', sprintf('pX trajectories - %s model', model_name));
            for i = 1:length(cases)
                subplot(length(cases), 1, i);
                hold on;

                % Plot individual subjects as faint lines
                for subj = 1:Ns
                    plot(px_values{i}(subj, :), 'Color', [colors(i,:), 0.2], ...
                        'LineWidth', 0.8);
                end

                % Plot mean as thick dark line
                mean_ = mean(px_values{i}, 1);
                plot(mean_, 'Color', colors(i,:), 'LineWidth' , 1.8);

                ylabel('pX precision', 'FontSize', 10);
                xlabel('Trial', 'FontSize', 10);
                title(sprintf('pX precision power - %s (n=%d subjects)', cases(i).title, Ns), ...
                    'FontSize', 11, 'FontWeight', 'bold');
                grid on;
                hold off;
            end
            sgtitle(sprintf('pX across trials - %s model, %s difficulty', ...
                model_name, difficulty), 'FontSize', 14, 'FontWeight', 'bold');


        end

    else

        % to do change this to reflect cases
        x1 = SimulParam1.x ; % should be PP
        x2 = SimulParam2.x ; % should be UP
        pred_precision_values_PP_time = exp(x1(5, :)) ; % take predictive precision
        pred_precision_values = exp(x2(5, :)) ;

        pred_precision_values_PP_space = exp(x1(10, :)) ; % take spatial precision
        pred_precision_values_UP_space = exp(x2(10, :)) ;

        compPlot = figure('Name', 'Temporal Precision');
        ax1 = axes('Parent', compPlot);
        plot(ax1, pred_precision_values_PP_time, 'Color', 'blue');
        hold(ax1, 'on');
        plot(pred_precision_values, 'Color', 'red');
        hold(ax1, 'off');
        title(ax1, 'PP vs UP predictive precision on time');
        legend('PP', 'UP');


        compPlot = figure('Name', 'Spatial Precision');
        ax1 = axes('Parent', compPlot);
        plot(ax1, pred_precision_values_PP_space, 'Color', 'blue');
        hold(ax1, 'on');
        plot(pred_precision_values_UP_space, 'Color', 'red');
        hold(ax1, 'off');
        title(ax1, 'PP vs UP precision on space');
        legend('PP', 'UP');


    end


end