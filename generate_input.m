function [U, ISIm] = generate_input(isAuditory,  T_Predictable, paradigmNum, S_Predictable, deviantPercentage)
    % a function for generating the sensory input for the experiment
    % should be able to make it either visual or audio based on flag
    % then for each modality can have P or UP case (predictable/unpredictable)
    % Start with audition, even predictable case can have variation where timing between stimuli is increasing/decreasing and is also predictable
    % Even in audition, can have the 2 different experiment paradigms for sound generation
    % reference is Morillon 2016

    %
    % Inputs:
    % - isAuditory: indicates whether the paradigm is auditory or visual, default is auditory
    % - T_Predictable: indicates whether the case is temporally predictable or up regardless of paradigm
    % - paradigmNum: which experiment, currently relative only to auditory which has 2 in paper
    % - S_Predictable: indicates whether the case is predictable or up regardless of paradigm, spectral for auditory, spatial for visual



    arguments
        % this gives default values , in this case the first auditory paradigm and the predictable case
        isAuditory logical = true
        T_Predictable = true
        paradigmNum = 1 % starts from 1
        S_Predictable = true
        deviantPercentage = 0.2

    end

    if isAuditory == true

        if (paradigmNum == 1)
            % params
            Ua = [0 1] ;
            ISIm = [255, 290, 345, 445, 770] ; % default from paper
            % ISIm = [255, 500, 750, 900, 1300] ; % second isi params to test more surprise
            trials_per_block = 50  ;
            num_blocks = 4 ;
            min_gap = 3;                           % min non-targets between targets

            U = [];   % final matrix (3 rows: target indicator, target value, ISI)

            for block = 1:num_blocks
                for isi_idx = 1:length(ISIm)
                    % 1. Target positions with spacing >= min_gap
                    num_targets = round(trials_per_block * deviantPercentage);
                    pattern = gen_pattern(trials_per_block, num_targets, min_gap);

                    % 2. Random target values (0 or 1) for each target
                    target_vals = randi([0 1], 1, num_targets);
                    Ua = zeros(1, trials_per_block);
                    Ua(pattern == 1) = target_vals;

                    % 3. ISI assignment
                    if T_Predictable
                        % --- Predictable: constant ISI in this block ---
                        ISI_vals = repmat(ISIm(isi_idx), 1, trials_per_block);
                    else
                        % --- Unpredictable: random ISIs with pre/post target equality ---
                        ISI_vals = ISIm(randi(length(ISIm), 1, trials_per_block));
                        target_pos = find(pattern == 1);
                        for p = target_pos
                            % Skip targets at block boundaries (cannot have both neighbours)
                            if p == 1 || p == trials_per_block
                                continue;
                            end
                            % Choose a random ISI and assign to target and its neighbours
                            common_isi = ISIm(randi(length(ISIm)));
                            % ISI_vals(p-1) = common_isi; % if I assume Isi at pos p is already between p and p-1 then no need to change this as each between it and previous
                            ISI_vals(p)   = common_isi;
                            ISI_vals(p+1) = common_isi;
                        end
                    end

                    % Combine and append block
                    addedU = [pattern; Ua; ISI_vals];
                    U = [U, addedU];
                end
            end

            % Display first few trials
            disp(U(:, 1:10)) ;


            % for each case of ISI generate 4 blocks of 50 trials (10 of those are target)
            % in each of those then do the deviant/standard percentage
            % after shuffles the blocks
            % U = zeros(3, trials_per_block * num_blocks * length(ISIm));
            % U = [] ;
            % for j= 1:num_blocks
            %     for i=1:length(ISIm)
            %         targets = ones(1, trials_per_block * deviantPercentage) ;
            %         non_targets = zeros(1, trials_per_block * (1- deviantPercentage)) ;

            %         Uv = [targets non_targets] ;
            %         Uv = Uv(randperm(length(Uv))); % problem here is that the random generation gives occasional targets directly after each other
            %         target_value = randi([0 1], 1, length(targets)) ;
            %         Ua = zeros(1, trials_per_block) ;

            %         Ua(find(Uv == 1)) = target_value ;
            %         ISI_vals = repmat(ISIm(i) , 1, trials_per_block) ;
            %         disp(size(ISI_vals))
            %         addedU  = [Uv; Ua; ISI_vals] ;
            %         U = [U addedU] ;
            %     end
            % end
            % if (~T_Predictable)
            %     disp("unpredictable, .. shuffling..")
            %     m = size(U, 2);
            %     U = U(:, randperm(m)); % same problem with multiple 1's possible being in a row due to random shuffling, should fix this here and above

            %     % here ensure pre and post target isi is same
            % end
            % disp(U(:, 1:10)) ;





        elseif (paradigmNum == 2) % experiment B in morrilon paper
            % here U should be of style [visual_cue; actual_auditory_cue; ISI/SOA; ] , and later on when playing sound could perhaps pass in different tones or not depending on the visual cue
            % if it's a S+ case, then all is same anyways, and in S- case then upon getting a 1 as v_cue (go trial) make spectral noise different
            % currently for U(4) always 0, and if s unpredictable the target pos will have a different value (1)

            % Generate trials for Experiment 2: 2x2 factorial design
            % T_Predictable: true/false for temporal predictability
            % S_Predictable: true/false for spectral predictability

            % Parameters from Experiment 2
            ISIm = [200, 300, 400, 500];  % SOA values in ms
            ISIv = 0.05;  % ISI variance for aperiodic sequences
            target_freq = 2027;  % Hz - intersection of pink/blue noise spectra
            reference_noise_level = 40;  %#ok<*NASGU> % dB SPL

            % Sequence parameters
            NBchunk = 96;  % Number of stimuli per trial (from exp description)
            Ua = [0 1];  % 0 = reference noise, 1 = target tone present/absent

            % Generate the sequence of stimulus types
            Nrep = NBchunk/2;
            Ia = repmat(Ua, 1, Nrep);  % Generate reference/target combinations
            Ioa = randperm(length(Ia));  % Shuffle them
            Itype = Ia(Ioa);  % Auditory stimulus types

            % Generate the sequence of SOAs based on temporal predictability
            if T_Predictable
                % T+ condition: constant intervals (2.5 Hz, 400 ms SOA)
                SOA_sequence = repmat(400, 1, NBchunk);
                t_type = 'Predictable';
            else
                % T- condition: random SOAs from five possible values
                SOA_sequence = ISIm(randi(length(ISIm), 1, NBchunk));
                t_type = 'UnPredictable';
            end

            % Generate spectral context based on spectral predictability
            % here pick one (blue or pink value, encoded as 0/1) ,
            % in case of predictable have all be that value, in case of unpredictable have the target be opposite
            spectral_value = randi([0 1], 1, 1) ; % generate random blue(0) or pink(1)
            if S_Predictable
                opposite_value = spectral_value ;
            else
                opposite_value = ~spectral_value ;
            end

            % Insert target tones pseudorandomly after 5-11 stimuli
            target_positions = [];
            current_pos = 0;
            while length(target_positions) < 12  % 12 target stimuli per trial
                gap = randi(7) + 4;  % 5-11 stimuli gap
                current_pos = current_pos + gap;
                if current_pos <= NBchunk
                    target_positions = [target_positions, current_pos];
                else
                    break;
                end
            end

            % Create the stimulus matrix
            U = zeros(4, NBchunk);  % 4 channels: visual_cue or not, target_present or not, SOA, (s factor?)

            % Fill in the stimulus matrix
            for i = 1:NBchunk
                U(2, i) = Itype(i);  % Target present (1) or reference (0)
                U(3, i) = SOA_sequence(i);  % SOA timing
                if (ismember(i, target_positions)) U(1, i) = 1 ; else U(1,i) =  0; end
                U(4, i) =  spectral_value ;

            end

            % Ensure pre-target and post-target SOAs are constant (400 ms)
            for pos = target_positions
                if pos > 1 && pos < NBchunk
                    SOA_sequence(pos-1) = 400;  % Pre-target
                    SOA_sequence(pos+1) = 400;  % Post-target
                    U(3, pos-1) = 400;
                    U(3, pos+1) = 400;
                end
                if ~S_Predictable
                    U(4, pos) = opposite_value ;
                end
            end

            % Display trial information
            fprintf('Total trials: %d\n', NBchunk);
            fprintf('Target positions: ');
            disp(target_positions);
            fprintf('Temporal predictability: %s\n', t_type);
            fprintf('Spectral predictability: %s\n', S_Predictable);

            % Generate the four conditions
            if (T_Predictable && S_Predictable)
                condition = 'T+S+';
            elseif  (T_Predictable == false &&  S_Predictable == false)
                condition = 'T-S-';
            elseif  (T_Predictable == false &&  S_Predictable == true)
                condition = 'T-S+';
            elseif  (T_Predictable == true &&  S_Predictable == false)
                condition = 'T+S-';
            end
            fprintf('Experimental condition: %s\n', condition);
            disp(U) ; % currently no manipulation of spectral aspect, that can be later ?


        else
            error("error")
        end

    else % VISUAL PARADIGM s
        % to do implement later on
        % should be a visual paradigm
        U =  zeros(2,sum(500+1));
    end



end



function pattern = gen_pattern(N, N1, min_gap)
    % N: total trials, N1: number of targets, min_gap: zeros between targets
    while true
        pattern = zeros(1, N);
        pattern(randperm(N, N1)) = 1;
        diffs = diff(find(pattern));

        if all(diffs > min_gap) && pattern(end) == 0 %
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