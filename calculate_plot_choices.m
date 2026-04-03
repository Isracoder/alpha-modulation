function [] = calculate_plot_choices(Ns, Mtype, U1, Y1, U2, Y2)

% Extract go trials (where visual input = 1)
go_trials = find(U1(1,:) == 1);

% Initialize arrays for summary stats
accuracy = zeros(1, Ns);
mean_RT_correct = zeros(1, Ns);
std_RT_correct = zeros(1, Ns);

std_RT_error = zeros(1, Ns);
mean_RT_error = zeros(1, Ns);

for k = 1:Ns
    % Calculate accuracy (only on go trials)
    responses = Y1{k}(1, go_trials);

    responses(responses == -1) = NaN;  % Exclude no-response trials
    %disp("how many response trials")
    %disp(size(responses(responses ~= -1))) % how many were response trials

    actual_stim = U1(2, go_trials);  % 0=standard, 1=deviant
    accuracy(k) = mean(responses == actual_stim, 'omitnan');

    % Calculate mean RT for correct and error trials
    correct_trials = go_trials(responses == actual_stim);
    error_trials = go_trials(responses ~= actual_stim & ~isnan(responses));

    if ~isempty(correct_trials)
        mean_RT_correct(k) = mean(Y1{k}(2, correct_trials));
        std_RT_correct(k) = std(Y1{k}(2, correct_trials)) ;
    end
    if ~isempty(error_trials)
        mean_RT_error(k) = mean(Y1{k}(2, error_trials));
        std_RT_error(k) = std(Y1{k}(2, error_trials)) ;
    end
end

% disp(mean_RT_correct(1, Ns)) ;

% Display summary
fprintf('\n=== SIMULATION SUMMARY ===\n');
fprintf('Model: %s\n', Mtype);
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


%% second case (Unpredictable / UP)
% Initialize arrays for summary stats
accuracy_UP = zeros(1, Ns);
mean_RT_correct_UP = zeros(1, Ns);
std_RT_correct_UP = zeros(1, Ns);

std_RT_error_UP = zeros(1, Ns);
mean_RT_error_UP = zeros(1, Ns);

for k = 1:Ns
    % Calculate accuracy (only on go trials)
    responses = Y2{k}(1, go_trials);

    responses(responses == -1) = NaN;  % Exclude no-response trials
    %disp("how many response trials")
    %disp(size(responses(responses ~= -1))) % how many were response trials

    actual_stim = U2(2, go_trials);  % 0=standard, 1=deviant
    accuracy_UP(k) = mean(responses == actual_stim, 'omitnan');

    % Calculate mean RT for correct and error trials
    correct_trials = go_trials(responses == actual_stim);
    error_trials = go_trials(responses ~= actual_stim & ~isnan(responses));

    if ~isempty(correct_trials)
        mean_RT_correct_UP(k) = mean(Y2{k}(2, correct_trials));
        std_RT_correct_UP(k) = std(Y2{k}(2, correct_trials)) ;
    end
    if ~isempty(error_trials)
        mean_RT_error_UP(k) = mean(Y2{k}(2, error_trials));
        std_RT_error_UP(k) = std(Y2{k}(2, error_trials)) ;
    end
end
fprintf('\n=== SIMULATION SUMMARY ===\n');
fprintf('Model: %s\n', Mtype);
fprintf('Number of subjects: %d\n', Ns);
fprintf('Mean accuracy: %.2f%% (SD: %.2f%%)\n', ...
    mean(accuracy_UP)*100, std(accuracy_UP)*100);
fprintf('Mean RT across subjects (correct): %.2f ms (SD: %.2f ms)\n', ...
    mean(mean_RT_correct_UP), std(mean_RT_correct_UP));
fprintf('Mean RT across subjects (error): %.2f ms (SD: %.2f ms)\n', ...
    mean(mean_RT_error_UP), std(mean_RT_error_UP));

fprintf('Mean RT 1st subject (correct): %.2f ms (SD: %.2f ms)\n', ...
    (mean_RT_correct_UP(1)), std_RT_correct_UP(1));
fprintf('Mean RT 1st subject (error): %.2f ms (SD: %.2f ms)\n', ...
    (mean_RT_error_UP(1)), std_RT_error_UP(1));



% to compare with other case as well

% X = categorical({type});
X = categorical({'Predictable' , 'Unpredictable'})
% X = reordercats(X,{'Periodic Predictable','Unpredictable'});

figure;
bar(X,[mean(accuracy) * 100  mean(accuracy_UP) * 100])
xlabel('Condition');
ylabel('Accuracy percentage');
title("Mean Accuracy graph")

figure ;
bar(X,[mean(mean_RT_correct)  mean(mean_RT_correct_UP) ])
title(['Mean Correct Reaction time (across ' num2str(Ns) ' subjects)']);    %% plotting histograms
xlabel('Condition');
ylabel('Reaction Time (ms)');


figure;
bar(X,[mean(mean_RT_error)  mean(mean_RT_error_UP)])
xlabel('Condition');
ylabel('Reaction Time (ms)') ;
title(['Mean Incorrect Reaction time (across ' num2str(Ns) ' subjects)']);    %% plotting histograms


end