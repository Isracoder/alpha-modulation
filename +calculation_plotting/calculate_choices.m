

function [accuracy, mean_RT_correct, std_RT_correct, std_RT_error, mean_RT_error, mean_dp, dp] = calculate_choices (Ns, model_name, Gt, difficulty, U, Y)
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

        if (Gt == 2 || Gt == 5); mean_dp(k) = mean(Y{k}(5, go_trials)) ; dp(k, :) = Y{k}(5, go_trials) ; end % if in sdt take third observable dprime


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
    fprintf('Model: %s\n', model_name);
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
