function [gx] = g_bay_ddm(x, P, u, inG)
% Alternative observation function for VBA oddball task.
% Implements a Bayesian decision model equivalent to a drift-diffusion model
% based on Bitzer et al. (2014), Frontiers in Human Neuroscience.
%
% INPUTS:
%   x    - hidden states from the evolution function (learning model)
%          x(3): mean of ISI prediction (mu)
%          x(5): log-precision of ISI prediction (log(Ppost)), where Ppost = exp(x(5))
%   P    - parameters (some log-transformed, some with custom transform)
%          P(1): log(lambda)          -> bound on posterior probability
%          P(2): log(t0)               -> non-decision time (s)
%          P(3): log(sigma_input)       -> input noise std (optional, can be fixed)
%          P(4): log(f_alpha)           -> alpha frequency (Hz)
%          P(5): log(A_alpha)           -> modulation amplitude (≥0)
%          P(6): raw_phi_inhib          -> transformed to inhibitory phase in [-π, π]
%   u    - input vector for the current trial
%          u(1): trial type (1 = visual/go trial, 0 = no-response trial)
%          u(2): stimulus category (1 = deviant, 0 = standard)
%          u(3): current inter-stimulus interval (isi)
%   inG  - fixed structure with additional options
%          inG.delta_t: time step for DDM simulation (e.g., 0.001)
%          inG.s_fixed: fixed diffusion coefficient (e.g., 0.1)
%          inG.mu_hat: internal model's feature mean for standard (e.g., -1) and deviant (e.g., 1)
%
% OUTPUTS:
%   gx   - [choice (0 or 1); reaction time (seconds)]
%          For no-response trials: gx = [-1; -1]

% --- Initialize output ---
gx = [-1; -1];

% --- Check for no-response trials ---
if u(1) == 0
    return;
end

% --- Extract states (from learning model) ---
mu_ISI = x(3);          % Mean of ISI prediction
Ppost = exp(x(5));      % Precision of ISI prediction (posterior precision)
% Note: Internal uncertainty sigma_hat^2 = 1/Ppost

% --- Extract observation parameters ---
A_alpha     = exp(P(1));    % modulation amplitude (≥0)
f_alpha     = exp(P(2));    % alpha frequency (Hz)
sigma_input = exp(P(3));     % input noise std (optional, may be fixed)
gam      = exp(P(4));
t0          = exp(P(5));    % non-decision time (s)
% new
lambda      = exp(P(6));    % bound on posterior probability [0.5, 1]
% Transform raw parameter to inhibitory phase in [-π, π]
phi_inhib   = 2 * atan(P(7));


% --- Fixed simulation parameters from inG ---
delta_t = inG.delta_t;   % Time step for simulation (seconds)
s_fixed = inG.s_fixed;   % Fixed diffusion coefficient (s in pDDM)
% Internal model's expected feature values for standard and deviant
mu_hat_std = inG.mu_hat(1);
mu_hat_dev = inG.mu_hat(2);

% --- Map experimental condition to input feature (μ_i) ---
% We assume the brain extracts a feature (e.g., perceived deviation) from the stimulus.
% This feature is noisy and centered on a value that depends on the stimulus category.
% For a standard (u(2)=0), the true feature is mu_hat_std.
% For a deviant (u(2)=1), the true feature is mu_hat_dev.
% if u(2) == 1 % Deviant
%     mu_i = mu_hat_dev;
% else % Standard
%     mu_i = mu_hat_std;
% end

% Assuming symmetric internal expectations: deviant = +M, standard = -M
M = mu_hat_dev;   % e.g., 1
if u(2) == 1      % deviant
    mu_i = M;
else              % standard
    mu_i = -M;
end

% --- Calculate equivalent DDM drift rate (v) and diffusion (s) ---
% Based on Bitzer et al. 2014, Equations (11) and (12), using the constraint
% of symmetric means (Section "Constraint: symmetric means").
% We also incorporate the learned ISI mean (mu_ISI) as a bias on the drift.
% This implements the idea that expectation of *when* modulates the evidence for *what*.

% The core term from the paper: v ∝ (μ_i * (μ_hat_dev - mu_hat_std)) / (sigma_hat^2)
% Here, sigma_hat^2 = 1/Ppost (internal uncertainty).
% The difference (μ_hat_dev - mu_hat_std) is constant.
% We can also let the learned mu_ISI modulate the drift, e.g., by shifting the effective μ_i.
% For simplicity, we'll use mu_ISI to scale the drift, assuming that expectation of
% a longer ISI (mu_ISI large) might amplify the perceived deviance.
% This part is a suggested extension and can be modified.

% Calculate internal uncertainty from precision
sigma_hat_sq = 1 / Ppost;

% Drift rate (v) - this is the key equation linking learning to DDM
% v = ( (mu_hat_dev^2 - mu_hat_std^2) / (2*delta_t^2*sigma_hat_sq) ) + ...
%     ( mu_i * (mu_hat_std - mu_hat_dev) / (delta_t^2*sigma_hat_sq) )
% For symmetric means (mu_hat_dev = -mu_hat_std = M), this simplifies.
% Let's assume symmetric means for clarity: mu_hat_dev = 1, mu_hat_std = -1.
M = mu_hat_dev; % Assuming mu_hat_dev = -mu_hat_std

% Simplified drift for symmetric means (Equation 21 in paper, but adapted)
% v = (2 * M * mu_i) / (delta_t^2 * sigma_hat_sq);
% We'll add a modulation by mu_ISI (learned mean). This is a novel extension.
% For example, if the actual ISI is longer than expected, it might increase drift for deviants.
isi_pred_err = u(3) - mu_ISI;
% modulation_factor = 1 + isi_prediction_error; % Simple linear modulation, can be changed

% % Final drift calculation
% v = (2 * M * mu_i * modulation_factor) / (delta_t^2 * sigma_hat_sq);
% Baseline drift (simplified symmetric case, Equation 21 from Bitzer et al.)
% v_base = (2 * M * mu_i) / (delta_t^2 * sigma_hat_sq);
% We add a small modulation by ISI prediction error to link temporal expectation.
% (This is an extension – can be removed or modified.)
v_base = (2 * M * mu_i * (1 + 0.1 * isi_pred_err)) / (delta_t^2 * sigma_hat_sq);

% --- Alpha phase at stimulus onset ---
% Assume alpha oscillator is reset to phase 0 at the moment of the previous stimulus.
% Then phase advances with frequency f_alpha during the ISI.
phase = mod(2 * pi * f_alpha * u(3), 2*pi);

% Modulation factor: 1 + A * cos(phase - phi_inhib)
% At phi_inhib, cos = 1 => factor = 1 + A (max facilitation if A>0 and inhibition defined as reduced drift?
% Actually we want inhibition at peak to reduce drift, so we set modulation = 1 - A*cos(phase - phi_inhib) if A is inhibition depth.
% Let's define: modulation = 1 - A_alpha * cos(phase - phi_inhib)
% Then at phase = phi_inhib, cos=1 => modulation = 1 - A (reduced drift, inhibition)
% At phase = phi_inhib+π, cos=-1 => modulation = 1 + A (increased drift, facilitation)
modulation = 1 - A_alpha * cos(phase - phi_inhib);
% Ensure modulation stays positive (though A_alpha < 1 for plausibility)
modulation = max(modulation, 0.1);  % lower bound to avoid negative drift

% Final drift rate
v = v_base * modulation;

% Diffusion coefficient (s) - we fix it as per pDDM convention
% s = (sigma_input * abs(mu_hat_std - mu_hat_dev)) / (delta_t * sigma_hat_sq);
% But we'll use the fixed value from inG to avoid over-parameterization.
% sig = s_fixed;
sig = sigma_input ;


% Bound on the decision variable (log posterior odds) - Equation (14)
B = log(lambda / (1 - lambda));

% --- Simulate the drift-diffusion process ---
% Initialize
y = 0; % Decision variable (log posterior odds)
t = 0;
max_steps = round(2.0 / delta_t); % Prevent infinite loops (e.g., 2 seconds max)

for i = 1:max_steps
    t = t + delta_t;

    % Update decision variable (discrete-time approximation)
    % dy = v*dt + s * sqrt(dt) * N(0,1)
    dy = v * delta_t + sig * sqrt(delta_t) * randn;
    y = y + dy;

    % Check bounds
    if y >= B
        gx(1) = 0; % Choose deviant (assuming bound crossing for deviant)
        gx(2) = t0 + t;
        break;
    elseif y <= -B
        gx(1) = 1; % Choose standard
        gx(2) = t0 + t;
        break;
    end
end

% If no bound was hit within max_steps, assign a default (e.g., random choice, long RT)
if gx(1) == -1
    gx(1) = round(rand); % Random choice
    gx(2) = t0 + t + 0.5; % Indicate a very long RT
end

end

%% Notes
%%%%% Notes

% Key Modifications & Interpretation
% Alpha Phase Computation – The phase at stimulus onset is calculated from the ISI and alpha frequency, assuming phase reset at each stimulus. This links temporal expectations (learned ISI) to the oscillatory state.

% Drift Modulation – The baseline drift (derived from internal uncertainty and stimulus feature) is multiplied by 1 - A*cos(phase - φ_inhib). This captures:

% Inhibition at peak: when phase ≈ φ_inhib, cos ≈ 1 → drift reduced (harder to accumulate evidence for the correct choice).

% Facilitation at trough: when phase ≈ φ_inhib+π, cos ≈ -1 → drift enhanced.

% New Parameters – f_alpha, A_alpha, and φ_inhib are added to P. They can be estimated from data, allowing the model to infer individual alpha frequency and the phase relationship that best explains behaviour.

% Usage Notes
% Ensure inG.mu_hat reflects your stimulus coding (e.g., standard = -1, deviant = +1).

% The modulation amplitude A_alpha should typically be <1 to keep drift positive; you can enforce this via a prior (e.g., log-normal with mean -1).

% The inhibitory phase φ_inhib is transformed from a real-valued parameter using 2*atan(), which maps the real line to (-π, π). This keeps the parameter identifiable and avoids circular wrapping issues during estimation.

% The additional modulation by isi_pred_err (commented as "extension") can be removed if you prefer a pure alpha‑phase effect. If kept, its weight (0.1) could also be a free parameter.
