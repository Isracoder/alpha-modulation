
function [U, ISIm] = generate_input(isAuditory, T_Predictable, paradigmNum, S_Predictable, deviantPercentage)
    % a function for generating the sensory input for the experiment
    % should be able to make it either visual or audio based on flag
    % then for each modality can have P or UP case (predictable/unpredictable)
    % Start with audition, even predictable case can have variation where timing between stimuli is increasing/decreasing and is also predictable
    % Even in audition, can have the 2 different experiment paradigms for sound generation
    % reference is Morillon 2016

    %
    % Inputs:
    % - isAuditory: indicates whether the paradigm is auditory or visual, default is auditory
    % - T_Predictable: indicates the temporal predictability pattern:
    %       = 1: completely predictable (constant ISI within block)
    %       = 0: completely unpredictable (random ISIs)
    %       = 0.3: mixture of predictable and unpredictable blocks (alternating)
    %       = 0.7: aperiodic predictable (increasing ISIs within block)
    % - paradigmNum: which experiment, currently relative only to auditory which has 2 in paper
    % - S_Predictable: indicates whether the case is predictable or up regardless of paradigm, spectral for auditory, spatial for visual

    arguments
        isAuditory logical = true
        T_Predictable = 1
        paradigmNum = 1
        S_Predictable = true
        deviantPercentage = 0.2
    end

    % ISIm = [255, 290, 345, 445, 770];
    ISIm = [255, 290, 345, 445, 610,  770];
    trials_per_block = 50; % default 50, 4, 3 %% CAREFUL, choosing a large number of trials per block leads to very long pattern generation time as it tries to ensure randomness but also a minimum gap
    num_blocks = 4;
    min_gap = 3;



    if isAuditory == true
        if (paradigmNum == 1)
            % params
            Ua = [0 1];


            U = [];


            for block = 1:num_blocks
                % Determine predictability pattern for this block (only used if T_Predictable == 0.3)
                % fprintf('block number: %d \n' , block) ;
                if T_Predictable == 0.3
                    % Alternating pattern: start with pred (1) for odd blocks, unpred (0) for even blocks
                    start_with_pred = mod(block, 2) == 1;   % odd block -> start with pred
                    pattern_predictable = zeros(1, length(ISIm));
                    for i = 1:length(ISIm)
                        pattern_predictable(i) = (start_with_pred && mod(i,2)==1) || (~start_with_pred && mod(i,2)==0);
                    end
                    % pattern_predictable(i) = 1 -> predictable (constant ISI), 0 -> unpredictable (random)
                end

                for isi_idx = 1:length(ISIm)
                    % 1. Target positions
                    num_targets = round(trials_per_block * deviantPercentage);
                    % fprintf('Isi Index: %d, number of targets: %d \n' , isi_idx, num_targets) ;
                    pattern = gen_pattern(trials_per_block, num_targets, min_gap);

                    % 2. Random target values
                    target_vals = randi([0 1], 1, num_targets);
                    Ua_row = zeros(1, trials_per_block);
                    Ua_row(pattern == 1) = target_vals;

                    % 3. ISI assignment based on T_Predictable (modified for 0.3)
                    if T_Predictable == 1
                        % All predictable
                        ISI_vals = repmat(ISIm(isi_idx), 1, trials_per_block);
                        % disp('generating predictable... \n')
                    elseif T_Predictable == 0
                        % All unpredictable
                        % disp('generating un-predictable... \n')
                        ISI_vals = ISIm(randi(length(ISIm), 1, trials_per_block));
                        target_pos = find(pattern == 1);
                        for p = target_pos
                            if p > 1 && p < trials_per_block
                                common_isi = ISIm(randi(length(ISIm)));
                                ISI_vals(p)   = common_isi;
                                ISI_vals(p+1) = common_isi;
                            end
                        end
                    elseif T_Predictable == 0.7

                        % Aperiodic unpredictable: cycling through ISI values (increase then decrease)
                        isi_values = ISIm;


                        trials_per_half = floor(trials_per_block / 2);

                        % Generate indices that cycle through ISI values
                        ISI_indices = zeros(1, trials_per_block);

                        % Increasing phase: go from 1 to length(isi_values)
                        for i = 1:trials_per_half
                            % Linear interpolation index from 1 to length(isi_values)
                            idx = 1 + (i-1) * (length(isi_values)-1) / (trials_per_half-1);
                            ISI_indices(i) = idx;
                        end

                        % Decreasing phase: go from length(isi_values) back to 1
                        for i = 1:(trials_per_block - trials_per_half)
                            % Linear interpolation index from length(isi_values) down to 1
                            idx = length(isi_values) - (i-1) * (length(isi_values)-1) / ((trials_per_block - trials_per_half)-1);
                            ISI_indices(trials_per_half + i) = idx;
                        end

                        % Convert indices to actual ISI values using interpolation
                        ISI_vals = zeros(1, trials_per_block);
                        for i = 1:trials_per_block
                            idx = ISI_indices(i);
                            idx_floor = floor(idx);
                            idx_ceil = ceil(idx);

                            if idx_floor == idx_ceil
                                % Exact match
                                ISI_vals(i) = isi_values(idx_floor);
                            else
                                % Interpolate between neighboring ISI values
                                fraction = idx - idx_floor;
                                ISI_vals(i) = round(isi_values(idx_floor) * (1-fraction) + isi_values(idx_ceil) * fraction);
                            end
                        end


                        jitter = 0.05 * randn(1, trials_per_block);
                        ISI_vals = round(ISI_vals .* (1 + jitter));

                        % Ensure values stay within bounds of the provided ISI range
                        ISI_vals = max(ISI_vals, min(ISIm));
                        ISI_vals = min(ISI_vals, max(ISIm));

                        % If pattern is provided, maintain pre/post target equality approximately
                        if ~isempty(pattern)
                            target_pos = find(pattern == 1);
                            for p = target_pos
                                if p > 1 && p < trials_per_block
                                    % Average the surrounding ISIs for target neighbors
                                    avg_isi = round((ISI_vals(p) + ISI_vals(p+1)) / 2);
                                    ISI_vals(p) = avg_isi;
                                    ISI_vals(p+1) = avg_isi;
                                end
                            end
                        end
                    elseif T_Predictable == 0.3
                        % Mixed: alternating predictable/unpredictable within block
                        if pattern_predictable(isi_idx) == 1
                            % Predictable segment: constant ISI
                            ISI_vals = repmat(ISIm(isi_idx), 1, trials_per_block);
                        else
                            % Unpredictable segment: random ISIs
                            ISI_vals = ISIm(randi(length(ISIm), 1, trials_per_block));
                            target_pos = find(pattern == 1);
                            for p = target_pos
                                if p > 1 && p < trials_per_block
                                    common_isi = ISIm(randi(length(ISIm)));
                                    ISI_vals(p)   = common_isi;
                                    ISI_vals(p+1) = common_isi;
                                end
                            end
                        end
                    else
                        error('T_Predictable must be 0, 0.3, 0.7, or 1');
                    end
                    % Combine and append block
                    addedU = [pattern; Ua_row; ISI_vals];
                    U = [U, addedU];
                end
            end

            disp(U(:, 1:10));

        elseif (paradigmNum == 2)
            % Experiment B parameters
            ISIm = [200, 300, 400, 500];
            NBchunk = 96;
            Ua = [0 1];

            Nrep = NBchunk/2;
            Ia = repmat(Ua, 1, Nrep);
            Ioa = randperm(length(Ia));
            Itype = Ia(Ioa);

            % Generate SOA sequence based on T_Predictable
            SOA_sequence = generate_temporal_pattern(NBchunk, ISIm, T_Predictable, [], [], []);

            % Generate spectral context
            spectral_value = randi([0 1], 1, 1);
            if S_Predictable
                opposite_value = spectral_value;
            else
                opposite_value = ~spectral_value;
            end

            % Insert target tones pseudorandomly after 5-11 stimuli
            target_positions = [];
            current_pos = 0;
            while length(target_positions) < 12
                gap = randi(7) + 4;
                current_pos = current_pos + gap;
                if current_pos <= NBchunk
                    target_positions = [target_positions, current_pos];
                else
                    break;
                end
            end

            % Create the stimulus matrix
            U = zeros(4, NBchunk);

            for i = 1:NBchunk
                U(2, i) = Itype(i);
                U(3, i) = SOA_sequence(i);
                U(1, i) = ismember(i, target_positions);
                U(4, i) = spectral_value;
            end

            % Ensure pre-target and post-target SOAs are constant (400 ms) for unpredictable conditions
            if T_Predictable == 0 || T_Predictable == 0.3
                for pos = target_positions
                    if pos > 1 && pos < NBchunk
                        SOA_sequence(pos-1) = 400;
                        SOA_sequence(pos+1) = 400;
                        U(3, pos-1) = 400;
                        U(3, pos+1) = 400;
                    end
                end
            end

            if ~S_Predictable
                for pos = target_positions
                    U(4, pos) = opposite_value;
                end
            end

            % Display trial information
            fprintf('Total trials: %d\n', NBchunk);
            % fprintf('Target positions: ');
            % disp(target_positions);
            fprintf('Temporal predictability: %s\n', get_temporal_type(T_Predictable));
            fprintf('Spectral predictability: %s\n', mat2str(S_Predictable));

            % Generate condition string
            condition = get_condition_string(T_Predictable, S_Predictable);
            fprintf('Experimental condition: %s\n', condition);
            disp(U);

        else
            error("Invalid paradigm number");
        end

    else % VISUAL PARADIGM
        % Parameters
        locations = [0, 1];


        U = [];
        for block = 1:num_blocks
            % Spatial predictability
            if S_Predictable
                loc_blk = locations(mod(block-1, length(locations)) + 1);
                block_locs = repmat(loc_blk, 1, trials_per_block);
            else
                block_locs = locations(randi(length(locations), 1, trials_per_block));
            end

            % Insert deviants (targets) with spacing
            num_targets = round(trials_per_block * deviantPercentage);
            pattern = gen_pattern(trials_per_block, num_targets, min_gap);
            target_vals = randi([0 1], 1, num_targets);
            Ua = zeros(1, trials_per_block);
            Ua(pattern == 1) = target_vals;

            % Generate temporal pattern (reusing the same function)
            isi_idx = mod(block-1, length(ISIm)) + 1;
            ISI_vals = generate_temporal_pattern(trials_per_block, ISIm, T_Predictable, pattern, isi_idx, block);

            % Combine rows
            addedU = [pattern; Ua; ISI_vals; block_locs];
            U = [U, addedU];
        end
    end
end

function ISI_vals = generate_temporal_pattern(trials_per_block, ISIm, T_Predictable, pattern, isi_idx, block)
    % Generate ISI values based on the temporal predictability parameter
    %
    % Inputs:
    %   trials_per_block: number of trials in this block
    %   ISIm: vector of possible ISI values
    %   T_Predictable: predictability value (0, 0.3, 0.7, or 1)
    %   pattern: target pattern (needed for target neighbor handling)
    %   isi_idx: index into ISIm for the base ISI value
    %   block: block number (for alternating patterns)

    % Default values for optional inputs
    if nargin < 4
        pattern = [];
    end
    if nargin < 5
        isi_idx = 1;
    end
    if nargin < 6
        block = 1;
    end

    if T_Predictable == 1
        % Completely predictable: constant ISI within block
        % disp('generating predictable... \n')
        ISI_vals = repmat(ISIm(isi_idx), 1, trials_per_block);

    elseif T_Predictable == 0
        % disp('generating UN-predictable... \n')
        ISI_vals = ISIm(randi(length(ISIm), 1, trials_per_block));

        % Ensure pre/post target ISIs are equal if pattern is provided
        if ~isempty(pattern)
            target_pos = find(pattern == 1);
            for p = target_pos
                if p > 1 && p < trials_per_block
                    common_isi = ISIm(randi(length(ISIm)));
                    ISI_vals(p) = common_isi;
                    ISI_vals(p+1) = common_isi;
                end
            end
        end

    elseif T_Predictable == 0.3
        % Mixture: some blocks predictable, some unpredictable
        % Alternating pattern based on block number
        if mod(block, 2) == 0
            % Even blocks: predictable (constant ISI)
            ISI_vals = repmat(ISIm(isi_idx), 1, trials_per_block);
        else
            % Odd blocks: unpredictable (random ISIs)
            ISI_vals = ISIm(randi(length(ISIm), 1, trials_per_block));

            % Ensure pre/post target ISIs are equal
            if ~isempty(pattern)
                target_pos = find(pattern == 1);
                for p = target_pos
                    if p > 1 && p < trials_per_block
                        common_isi = ISIm(randi(length(ISIm)));
                        ISI_vals(p) = common_isi;
                        ISI_vals(p+1) = common_isi;
                    end
                end
            end
        end

    elseif T_Predictable == 0.7
        % Aperiodic unpredictable: cycling through ISI values (increase then decrease)
        isi_values = ISIm;  % e.g., [200, 300, 400, 500, 800]

        % Create a smooth cycle that goes up then down through the ISI values
        % For a 50-trial block, we want: up (25 trials) then down (25 trials)
        trials_per_half = floor(trials_per_block / 2);

        % Generate indices that cycle through ISI values
        ISI_indices = zeros(1, trials_per_block);

        % Increasing phase: go from 1 to length(isi_values)
        for i = 1:trials_per_half
            % Linear interpolation index from 1 to length(isi_values)
            idx = 1 + (i-1) * (length(isi_values)-1) / (trials_per_half-1);
            ISI_indices(i) = idx;
        end

        % Decreasing phase: go from length(isi_values) back to 1
        for i = 1:(trials_per_block - trials_per_half)
            % Linear interpolation index from length(isi_values) down to 1
            idx = length(isi_values) - (i-1) * (length(isi_values)-1) / ((trials_per_block - trials_per_half)-1);
            ISI_indices(trials_per_half + i) = idx;
        end

        % Convert indices to actual ISI values using interpolation
        ISI_vals = zeros(1, trials_per_block);
        for i = 1:trials_per_block
            idx = ISI_indices(i);
            idx_floor = floor(idx);
            idx_ceil = ceil(idx);

            if idx_floor == idx_ceil
                % Exact match
                ISI_vals(i) = isi_values(idx_floor);
            else
                % Interpolate between neighboring ISI values
                fraction = idx - idx_floor;
                ISI_vals(i) = round(isi_values(idx_floor) * (1-fraction) + isi_values(idx_ceil) * fraction);
            end
        end

        % Add small random jitter (±5%) to make it less artificial
        jitter = 0.05 * randn(1, trials_per_block);
        ISI_vals = round(ISI_vals .* (1 + jitter));

        % Ensure values stay within bounds of the provided ISI range
        ISI_vals = max(ISI_vals, min(ISIm));
        ISI_vals = min(ISI_vals, max(ISIm));

        % If pattern is provided, maintain pre/post target equality approximately
        if ~isempty(pattern)
            target_pos = find(pattern == 1);
            for p = target_pos
                if p > 1 && p < trials_per_block
                    % Average the surrounding ISIs for target neighbors
                    avg_isi = round((ISI_vals(p) + ISI_vals(p+1)) / 2);
                    ISI_vals(p) = avg_isi;
                    ISI_vals(p+1) = avg_isi;
                end
            end
        end

    else
        error('T_Predictable must be 0, 0.3, 0.7, or 1');
    end
end

function type_str = get_temporal_type(T_Predictable)
    % Return a string description of the temporal pattern
    switch T_Predictable
        case 1
            type_str = 'Constant (Predictable)';
        case 0
            type_str = 'Random (Unpredictable)';
        case 0.3
            type_str = 'Mixed (Alternating blocks)';
        case 0.7
            type_str = 'Increasing (Aperiodic)';
        otherwise
            type_str = 'Unknown';
    end
end

function condition_str = get_condition_string(T_Predictable, S_Predictable)
    % Generate condition string for experiment 2
    t_str = '';
    s_str = '';

    if T_Predictable == 1
        t_str = 'T+';
    elseif T_Predictable == 0
        t_str = 'T-';
    elseif T_Predictable == 0.3
        t_str = 'Tm';
    elseif T_Predictable == 0.7
        t_str = 'Ta';
    end

    if S_Predictable
        s_str = 'S+';
    else
        s_str = 'S-';
    end

    condition_str = [t_str s_str];
end

function pattern = gen_pattern(N, N1, min_gap)
    % N: total trials, N1: number of targets, min_gap: zeros between targets
    while true
        % disp("...generating")
        pattern = zeros(1, N);
        pattern(randperm(N, N1)) = 1;
        diffs = diff(find(pattern));

        if all(diffs > min_gap) && pattern(end) == 0
            break;
        end
    end
end

%% original code for case 1

%  NBchunk = 40;   % number of chunks (must be even) , default was 150
%         Ua      = [0 1]; % 2 auditory (std/dev) & 2 visual (no-go/go) stimuli
%         ISIm    = 600;   % mean ISI in ms, can also use values from exp of [255, 290, 345, 445, or 770]
%         ISIv    = 0.05;  % ISI variance for aperiodic sequences, changed from 0.05, should I have fixed variance on one mean or no variance and shuffle means ?
%         Chunks  = 3:7;   % chunk size before a go trial (having to answer std or dev), [3, 4,5,6,7], in exp they did every 1.5-6 secs
%         % currently for example this gives 3 trials, then go, then 4 trials, then go, then 5 trials, then go, ...



%         % Generate the sequence of chunk types
%         Nrep    = NBchunk/2;
%         Ia      = repmat(Ua,1,Nrep); % generates 150 0s and 1s combined
%         Ioa     = randperm(length(Ia)); % shuffles them
%         Itype   = [ones(1,2*Nrep) ; Ia(Ioa)]; % generates 1s and other 1s or zeros, these are the go-trials with the bottom half representing std/dev

%         % Generate the sequence of chunk sizes
%         Nrep    = ceil(NBchunk/length(Chunks));  % here 30 reps with default case
%         Istim   = repmat(Chunks,Nrep); % repeat [3,4,5,6,7] 30 times , 30*150, this seems to expand implicitly to 1*5 , 30*30 resulting in 30 * 150
%         Iorder  = randperm(length(Istim)); % creates random nums from 1 to 150
%         Isize   = Istim(Iorder); % then takes randomly based on Iorder, so if (40, 29, ..) then (Istim(40), Istim(29)..)
%         Isize   = Isize(1:NBchunk); % here only as much as I need, from 1 to 150 numbers


%         U = zeros(2,sum(Isize+1)); % first part visual, second part auditory, and tracks ISI
%         ind = 0;
%         for i = 1:NBchunk
%             U(1,ind+Isize(i)+1) = Itype(1,i); % sets the visual input part as 0 or 1 (no response/response) to indicate no-go/go trials
%             U(2,ind+Isize(i)+1) = Itype(2,i); % sets the auditory input part as 0 or 1 (std/deviant)
%             ind = ind + Isize(i) + 1;
%         end
%         Nstim = length(U);

%         % After generating U, check how many go/no go trials (answer required or
%         % not)
%         fprintf('Total trials: %d\n', size(U,2));
%         fprintf('Go trials (U(1,:)==1): %d\n', sum(U(1,:)==1));
%         fprintf('No-go trials (U(1,:)==0): %d\n', sum(U(1,:)==0));

%         % Generate the sequence of ISI

%         % currently I'm doing and returning both, later on should only be one
%         % U_both = cell(1,2) ;
%         % Uisi = repmat(ISIm,1,Nstim);
%         % U_both{1,1} =[U ; Uisi];    % for periodic case
%         % Uisi = log(ISIm) + sqrt(ISIv)*randn(1,Nstim);
%         % U_both{1,2} =[U ; exp(Uisi)]; % for aperiodic case


%         switch T_Predictable
%             case {1, true} % periodic model
%                 Uisi = repmat(ISIm,1,Nstim);
%                 U =[U ; Uisi];
%                 % U = U_both{1,1} ;
%                 type = 'Periodic Predictable' ;
%             case {0 , false} % aperiodic unpredictable model
%                 Uisi = log(ISIm) + sqrt(ISIv)*randn(1,Nstim);
%                 U =[U ; exp(Uisi)];
%                 % U = U_both{1,2} ;
%                 type = 'UnPredictable' ;
%             otherwise
%                 error('Use 1/0 for sequence generation flag')
%         end
%         fprintf('Trial Type (PP or UP): %s\n', type);
%         format shortg
%         disp(U ) ;