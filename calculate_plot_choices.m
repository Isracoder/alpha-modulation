function [] = calculate_plot_choices(Ns, Mtype, Gt,  U1, Y1, U2, Y2)

    [accuracy_PP, mean_RT_correct_PP, std_RT_correct_PP, std_RT_error_PP, mean_RT_error_PP, mean_dp_PP] = calculate_choices(Ns, Mtype, Gt, U1, Y1) ;
    [accuracy_UP, mean_RT_correct_UP, std_RT_correct_UP, std_RT_error_UP, mean_RT_error_UP, mean_dp_UP] = calculate_choices(Ns, Mtype, Gt, U2, Y2) ;

    X = categorical({'Predictable' , 'Unpredictable'}) ;

    figure;
    bar(X,[mean(accuracy_PP) * 100  mean(accuracy_UP) * 100])
    xlabel('Condition');
    ylabel('Accuracy percentage');
    title("Mean Accuracy graph")

    figure ;
    bar(X,[mean(mean_RT_correct_PP)  mean(mean_RT_correct_UP) ])
    title(['Mean Correct Reaction time (across ' num2str(Ns) ' subjects)']);    %% plotting histograms
    xlabel('Condition');
    ylabel('Reaction Time (ms)');


    figure;
    bar(X,[mean(mean_RT_error_PP)  mean(mean_RT_error_UP)])
    xlabel('Condition');
    ylabel('Reaction Time (ms)') ;
    title(['Mean Incorrect Reaction time (across ' num2str(Ns) ' subjects)']);    %% plotting histograms

    if (Gt == 6) % in case of SDT model plot d prime across conditions
        figure;
        bar(X,[mean(mean_dp_PP)  mean(mean_dp_UP)])
        xlabel('Condition');
        ylabel('d prime averaged') ;
        title(['D prime (across ' num2str(Ns) ' subjects)']);    %% plotting histograms
    end


end


function [accuracy, mean_RT_correct, std_RT_correct, std_RT_error, mean_RT_error, mean_dp] = calculate_choices (Ns, Mtype, Gt, U, Y)
    % Extract go trials (where visual input = 1)
    go_trials = find(U(1,:) == 1);

    % Initialize arrays for summary stats
    accuracy = zeros(1, Ns);
    mean_RT_correct = zeros(1, Ns);
    std_RT_correct = zeros(1, Ns);

    std_RT_error = zeros(1, Ns);
    mean_RT_error = zeros(1, Ns);

    mean_dp = zeros(1, Ns);

    for k = 1:Ns % across participants
        % Calculate accuracy (only on go trials)
        responses = Y{k}(1, go_trials);

        % responses(responses == -1) = NaN;  % Exclude no-response trials, no need since we already checked go trials?
        %disp("how many response trials")
        %disp(size(responses(responses ~= -1))) % how many were response trials

        actual_stim = U(2, go_trials);  % 0=standard, 1=deviant
        accuracy(k) = mean(responses == actual_stim, 'omitnan');

        % Calculate mean RT for correct and error trials
        correct_trials = go_trials(responses == actual_stim);
        error_trials = go_trials(responses ~= actual_stim & ~isnan(responses));

        if (Gt == 6); mean_dp = mean(Y{k}(3, go_trials)) ; end ; % if in sdt take third observable dprime

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