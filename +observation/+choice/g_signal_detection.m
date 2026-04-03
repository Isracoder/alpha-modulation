function [gx] = g_signal_detection(x,P,u,inG)
% Observation function based on Signal Detection Theory (SDT).
% Inputs:
%   x   - hidden states from f_Audio_H1
%   P   - model parameters (1:A0, 2:f, 3:sig, 4:gam, 5:t0)
%   u   - inputs: u(1)=visual trial flag, u(2)=standard/devian flag, u(3)=ISI
%   inG - input structure (contains PhiOpt, unused here)
% Outputs:
%   gx(1) : choice (0 = deviant, 1 = standard)
%   gx(2) : reaction time (ms)

gx = zeros(2,1);

% States from learning model
mu    = x(1);                % posterior mean of ISI (ms)
Ppost = exp(x(5));           % predictive precision (1/ms^2)
% Tref  = x(6);              % elapsed time (not used)

% Parameters (only t0 and gam are used)
t0  = exp(P(5));             % non‑decision time (ms)
gam = exp(P(4));             % criterion offset (ms) – positive = bias toward "standard"

% Inputs
Uv = u(1);                   % 1 = visual trial, 0 = non‑visual
Ua = u(2);                   % 0 = standard, 1 = deviant
isi = u(3);                  % actual ISI on this trial (ms)

if Uv == 1
    % Criterion: expected ISI plus a constant offset
    criterion = mu + gam;

    % Probability of responding "deviant" (choice 0)
    % For a standard trial, this is the false alarm rate.
    % For a deviant trial, this is the hit rate.
    z = (criterion - isi) * sqrt(Ppost);
    p_choice_0 = 1 - 0.5 * (1 + erf(z / sqrt(2)));   % equivalent to normcdf(-z)

    % Deterministic choice (as in original DDM version)
    if p_choice_0 > 0.5
        gx(1) = 0;           % deviant
    else
        gx(1) = 1;           % standard
    end

    % note that perhaps rt should rely on periodicity not predictability

    % Reaction time: non‑decision time + a term that decreases with evidence strength
    % Evidence strength = absolute distance to criterion in units of noise
    evidence = abs(criterion - isi) * sqrt(Ppost); % the bigger the difference is, the further off I was, the longer it should take

    % rt_decision = 1 / (evidence + eps);   % arbitrary scaling, prevents division by zero
    %  currently can scale to between 200 and 300 ms ?
    rt_decision = rescale(evidence, 180, 300)  ;% scale
    gx(2) = t0 + (rt_decision);

else
    % Non‑visual trials – no response expected
    gx(1) = -1;
    gx(2) = -1;
end
end