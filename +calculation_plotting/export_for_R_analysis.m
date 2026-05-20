function export_for_R_analysis(Ns, Mtype, Gt, cases, difficulty, output_dir , metrics)
    % EXPORT_FOR_R_ANALYSIS Export subject-level data for R analysis
    model_name = get_model_name(str2num(Mtype(2)), Gt);

    % Define metrics
    % metrics = [
    %     struct('name', 'Accuracy', 'field', 'accuracy', 'multiplier', 100);
    %     struct('name', 'Correct_RT', 'field', 'mean_RT_correct', 'multiplier', 1);
    %     struct('name', 'Error_RT', 'field', 'mean_RT_error', 'multiplier', 1);
    %     struct('name', 'Dprime', 'field', 'mean_dp', 'multiplier', 1)
    % ];

    if Gt ~= 2 && Gt ~= 5
        metrics = metrics(1:3);
    end

    % Initialize data structure
    all_data = struct();
    all_data.model = model_name;
    all_data.difficulty = difficulty;
    all_data.N_subjects = Ns;
    all_data.N_cases = length(cases);

    % Extract data for each subject and case
    for m = 1:length(metrics)
        % metric_data = [];
        metric_data = {};


        for i = 1:length(cases)
            [accuracy, mean_RT_correct, ~, ~, mean_RT_error, mean_dp, ~] = ...
                calculation_plotting.calculate_choices(Ns, model_name, Gt, difficulty, cases(i).U, cases(i).Y);

            metrics(1).data{i} = accuracy;
            metrics(2).data{i} = mean_RT_correct;
            metrics(3).data{i} = mean_RT_error;
            if Gt == 2 || Gt == 5
                metrics(4).data{i} = mean_dp;
            end

            values = metrics(m).data{i} * metrics(m).multiplier; % guaranteed double

            for subj = 1:Ns
                metric_data(end+1, :) = {subj, i, values(subj), cases(i).title};
            end
        end



        T = cell2table(metric_data, 'VariableNames', {'Subject', 'Case', 'Value', 'CaseName'});
        T.Subject = categorical(T.Subject);
        T.Case    = categorical(T.Case);

        timestamp = datestr(now, 'yyyy_mm_dd_HH_MM_SS');
        filename  = fullfile(output_dir, ...
            sprintf('%s_%s_%s_%s.csv', metrics(m).name, model_name, difficulty, timestamp));
        writetable(T, filename);
        fprintf('Saved: %s\n', filename);

        % T = cell2table(metric_data, ...
        %     'VariableNames', {'Subject', 'Case', 'Value', 'CaseName'});

        % % Subject/Case as integers are already clean for R; categorical is optional
        % T.Subject  = categorical(T.Subject);
        % T.Case     = categorical(T.Case);

        % % Save

        % timestamp = datestr(now, 'yyyy_mm_dd_HH_MM_SS');

        % filename = fullfile(output_dir, ...
        %     sprintf('%s_%s_%s_%s.csv', metrics(m).name, model_name, difficulty, timestamp));
        % writetable(T, filename);

        % fprintf('Saved: %s\n', filename);
    end

    % Also save metadata
    meta_file = fullfile(output_dir, ...
        sprintf('metadata_%s_%s.txt', model_name, difficulty));
    fid = fopen(meta_file, 'w');
    fprintf(fid, 'Model: %s\n', model_name);
    fprintf(fid, 'Difficulty: %s\n', difficulty);
    fprintf(fid, 'N_subjects: %d\n', Ns);
    fprintf(fid, 'Cases:\n');
    for i = 1:length(cases)
        fprintf(fid, '  %d: %s\n', i, cases(i).title);
    end
    fclose(fid);
end