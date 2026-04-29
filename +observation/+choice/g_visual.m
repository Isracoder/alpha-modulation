function [gx] = g_visual(x_states, phi_params, u_input, inG)
    % Observation function for visual 4‑square oddball task.
    % Models choice, reaction time, and bilateral alpha (amplitude & phase).
    %
    % INPUTS
    %   x(1)   : μ_t   – posterior mean ISI (ms)
    %   x(2)   : log π_t – log posterior precision (temporal)
    %   x(5)   : log predictive precision (temporal)
    %   x(6)   : time accumulator (s)
    %   x(9)   : μ_s   – posterior mean location (continuous, -1 left ... +1 right)
    %   x(10)  : log π_s – log posterior precision (spatial)
    %   (other states unused in this observation)
    %
    %   P(1)   : A0      – baseline alpha amplitude (µV)
    %   P(2)   : f       – alpha frequency (Hz)
    %   P(3)   : sig     – unused (kept for compatibility)
    %   P(4)   : gam     – RT scaling factor (ms)
    %   P(5)   : t0      – non‑decision time (ms)
    %   P(6)   : std_tone– value for standard stimulus (e.g., 440 Hz)
    %   P(7)   : dev_tone– value for deviant stimulus
    %   P(8)   : same_spectral – not used here, keep for compatibility
    %   P(9)   : k_t     – sensitivity of temporal scaling (higher = steeper)
    %   P(10)  : thresh_t– midpoint for temporal scaling
    %   P(11)  : k_s     – sensitivity of spatial lateralization
    %   P(12)  : thresh_s– midpoint for spatial lateralization
    %
    %   u(1)   : visual trial flag (1 = go, 0 = no‑go)
    %   u(2)   : actual stimulus (0 = standard, 1 = deviant)
    %   u(3)   : actual ISI (ms)
    %   u(4)   : actual location (0 = left, , 2 = right) / can change to -1 , 1
    %
    %   inG    : structure with field .PhiOpt (optional phase offset)
    %
    % OUTPUTS
    %   gx(1)  : choice (0 = standard, 1 = deviant) on go trials, else 0
    %   gx(2)  : reaction time (ms) on go trials, else 0
    %   gx(3)  : alpha amplitude left hemisphere (µV)       % later on perhaps have (left amp , left phase) and (right amp, right phase) following each other
    %   gx(4)  : alpha amplitude right hemisphere (µV)
    %   gx(5)  : alpha phase left (radians)
    %   gx(6)  : alpha phase right (radians)
    %   gx(7)  : d‑prime (discriminability)
    %__________________________________________________________________________

    gx = zeros(7,1);
    PhiOpt = inG.PhiOpt;   % optional phase offset (scalar)

    % ---- Extract states ----
    mu_t    = x_states(1);                % posterior mean ISI (ms)
    prec_t  = exp(x_states(2));           % posterior precision ISI (1/ms²)
    pred_prec_t = exp(x_states(5));       % predictive precision (1/ms²)
    t_elapsed = x_states(6);              % elapsed time (s)

    mu_s    = x_states(9);                % posterior mean location (continuous -1..1)
    prec_s  = exp(x_states(10));          % posterior precision location (1/unit²)

    % ---- Observation parameters ----
    A0      = phi_params(1);                % baseline alpha amplitude (µV)
    f_alpha = phi_params(2);                % alpha frequency (Hz)
    gam     = phi_params(4);                % RT scaling factor (ms)
    t0      = phi_params(5);                % non‑decision time (ms)
    std_tone = phi_params(6);
    dev_tone = phi_params(7);
    k_t     = phi_params(9);                % slope of temporal scaling
    thresh_t = phi_params(10);              % midpoint of temporal scaling
    k_s     = phi_params(11);               % slope of spatial lateralization
    thresh_s = phi_params(12);              % midpoint of spatial lateralization

    % ---- Inputs ----
    go_trial  = u_input(1);              % 1 = subject must respond
    actual_stim = u_input(2);            % 0 = standard, 1 = deviant
    actual_isi = u_input(3);             % ms
    actual_loc = u_input(4);             %


    if go_trial == 1
        % Convert actual tone to log scale for signal detection
        mu_std  = log(std_tone);
        mu_dev  = log(dev_tone);
        % Use temporal predictive precision as sensitivity (inverse variance)
        sigma = 1 / sqrt(pred_prec_t);  % later have location also modulate sigma
        d_prime = (mu_dev - mu_std) / sigma;
        criterion = (mu_std + mu_dev) / 2;  % unbiased criterion
        % Draw internal response
        if actual_stim == 0
            internal = mu_std + sigma * randn();
        else
            internal = mu_dev + sigma * randn();
        end
        choice = double(internal > criterion); % VERIFY
        gx(1) = choice;
        % RT: faster when d' is higher (easier discrimination)
        RT = t0 + gam / (d_prime + eps);
        gx(2) = RT;
        gx(7) = d_prime;   % store d' for debugging
    else
        gx(1) = 0;
        gx(2) = 0;
        gx(7) = 0;
    end

    %% Alpha amplitude and phase

    % first: Temporal scaling factor (0..1) from temporal precision
    %     Use logistic: T_scale = 1 / (1 + exp(-k_t*(prec_t - thresh_t)))
    T_scale = 1 / (1 + exp(-k_t * (prec_t - thresh_t)));
    % When temporal precision is very low, T_scale → 0 → almost no alpha.
    % When high, T_scale → 1.

    % Second: Spatial lateralization factor (-1..1) from spatial precision & expectation
    %     lateralization = +1 if expecting stimulus to the right (mu_s > 0)
    %                    -1 if expecting left
    %                    0 if centre or uncertain.
    %     Strength increases with spatial precision.
    raw_lat = tanh(k_s * (prec_s - thresh_s));  % ranges -1..1, steepness k_s
    % Multiply by sign of expected location (mu_s) – where mu_s is continuous.
    % However mu_s may be >0 for right, <0 for left.
    lat_factor = raw_lat * sign(mu_s);   % if mu_s=0, lat_factor=0
    % lat_factor positive → bias toward right hemisphere? We'll define:
    % Positive lat_factor means more alpha in right hemisphere (ipsilateral
    % to right expectation) and less in left. Negative means more alpha in left.

    % Compute left and right amplitudes
    % Baseline A0 * T_scale gives overall amplitude level.
    % lateralization shifts balance:
    %   right_amplitude = A0 * T_scale * (1 + lat_factor)
    %   left_amplitude  = A0 * T_scale * (1 - lat_factor)
    % This ensures when lat_factor = +1, right gets 2*A0*T_scale, left gets 0.
    % When lat_factor = -1, left gets double, right zero.
    % When lat_factor = 0, both get A0*T_scale.
    % We add a small epsilon to avoid zero (physiologically unrealistic).
    eps_amp = 0.1;
    left_amp  = A0 * T_scale * (1 - lat_factor) + eps_amp;
    right_amp = A0 * T_scale * (1 + lat_factor) + eps_amp;

    gx(3) = left_amp;
    gx(4) = right_amp;

    % Third: Phase: driven by expected stimulus timing (mu_t) and elapsed time.
    %     For left and right we can keep the same phase (coherent) or add
    %     a small offset if needed. Here we use identical phase.
    %     The phase is locked to the predicted onset of the *next* stimulus:
    %     predicted next stimulus time = t_elapsed + mu_t/1000.
    %     We compute phase = 2π * f_alpha * (t_elapsed + mu_t/1000) + PhiOpt
    predicted_next_time = t_elapsed + mu_t / 1000;
    phase = 2*pi * f_alpha * predicted_next_time + PhiOpt;
    gx(5) = phase;   % left phase
    gx(6) = phase;   % right phase , CHECK literature for evidence for/against different phases in hemispheres

end


%% SPATIAL COMPONENT
% spatial belief: posterior mean location mu_s (in [-1,1]) and precision π_s
% expected_side = sign(mu_s);   % -1 = left, +1 = right
% alpha_amp_left  = A0 * (pred_prec / (pred_prec + spatial_prec)) * (1 - 0.5*(1+expected_side));
% alpha_amp_right = A0 * (spatial_prec / (pred_prec + spatial_prec)) * (1 + 0.5*(1-expected_side));