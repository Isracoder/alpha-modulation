function [] = plot_kuramoto_trace()

    % each case is a separate file, ex. hopf_trajectories_casePP.mat, for one subject
    % each file has trajectories and time steps
    % in the trajectories I have a certain number of cells (trial points)
    % each trial point has an array of 1 X 1000 which represents the simulation timesteps solved
    % here we concatenate and plot

    % Define cases and parameters
    cases = [struct('name', 'PP', 'title', 'Case PP'), ...
        struct('name', 'AP', 'title', 'Case AP'), ...
        struct('name', 'UP', 'title', 'Case UP')
        ];
    Ns = 1; %
    colors = lines(length(cases)); % Color scheme

    % Initialize cell array to hold all x_values
    x_values = cell(length(cases), 1);

    % Load data from each case file
    for i = 1:length(cases)
        filename = sprintf('hopf_trajectories_%s_2026_05_16_14.mat', cases(i).name); % hopf_trajectories_AP_2026_05_16_14.mat

        if exist(filename, 'file')
            data = load(filename);


            trajectories = data.trajectories;

            n_trials = length(trajectories);

            fprintf('Number of trials: %d, length of trajectory: %d' , n_trials , length(trajectories{1})) ;
            % Initialize matrix: subjects x timesteps
            x_values{i} = zeros(1 , n_trials * length(trajectories{1}));

            for trial = 1:n_trials
                if ~isempty(trajectories{trial})
                    % Ensure consistent length (trim or pad if necessary)
                    traj_length = length(trajectories{trial}) ;
                    % Calculate start and end indices for this trial
                    start_idx = (trial-1) * traj_length + 1;
                    end_idx = trial * traj_length;

                    % Insert the trajectory at the correct position
                    x_values{i}(start_idx:end_idx) = trajectories{trial}(1:traj_length);
                end
            end
        else
            warning('File not found: %s', filename);
            x_values{i} = []; % Empty if file missing
        end
    end

    % Check if we have data before plotting
    if all(cellfun(@isempty, x_values))
        error('No trajectory data found. Check that files exist.');
    end

    % Create figure for x value trajectories - Kuramoto
    figure('Name', 'X values trajectories - Kuramoto model') ;
    % 'Position', [100, 100, 800, 200*length(cases)]);

    for i = 1:length(cases)
        subplot(length(cases), 1, i);
        hold on;

        % Skip if no data for this case
        if isempty(x_values{i})
            continue;
        end

        plot(x_values{i}, 'Color', [colors(i,:), 0.2], ...
            'LineWidth', 1);

        ylabel('X values', 'FontSize', 10);
        xlabel('Simulation Timestep', 'FontSize', 10);
        title(sprintf('X values - %s (n=%d subjects)', ...
            cases(i).title, Ns), ...
            'FontSize', 11, 'FontWeight', 'bold');
        grid on;
        hold off;
    end

    sgtitle('X value trajectories - Kuramoto model', ...
        'FontSize', 14, 'FontWeight', 'bold');



    % legend, fix later
    % subplot(length(cases), 1, length(cases));
    % legend_handles = [plot(nan, 'Color', [0 0 0 0.2], 'LineWidth', 0.8), ...
    %     plot(nan, 'Color', [0 0 0], 'LineWidth', 1.8)];
    % legend(legend_handles, {'Individual subjects', 'Group mean'}, ...
    %     'Location', 'best');


    compPlot = figure('Name', 'X values Comparison');
    ax1 = axes('Parent', compPlot);
    for i = 1:length(cases)
        plot(ax1, (x_values{i}), 'Color', colors(i,:), 'LineWidth', 0.8);
        hold(ax1, 'on');
    end
    hold(ax1, 'off');
    xlabel('Timesteps');
    set(ax1, 'FontSize' , 14) ;
    ylabel('X values');
    title(ax1, 'X value Comparison - Gamma + Kuramoto-Hopf' , 'FontSize', 14);
    legend(cases.title);




end