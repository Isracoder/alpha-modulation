function [gx] = g_choice2(x, P, u, inG)
% x  = hidden states
% P  = observation parameters
% u  = input [Uv; Ua; isi]

% Unpack states and parameters
mu    = x(3);
Ppost = exp(x(5));        % posterior precision
Tref  = x(6);

A0 = exp(P(1));  % amplitude
f  = exp(P(2));  % frequency
sig= exp(P(3));  % diffusion noise
gam= exp(P(4));  % threshold
t0 = exp(P(5));  % non-decision time

Uv = u(1);
Ua = u(2);
isi = u(3);

if Uv == 0
    % No response required
    gx = [-1; -1];
    % dgdx = []; dgdP = [];   % or zeros of appropriate size
    return
end

% Compute entropy and phase term (as before)
S = 0.5 * log(2*pi*exp(1) / Ppost);
Phi = inG.PhiOpt - 2*pi*f*(Tref + mu);
phase_term = sin(2*pi*f*(Tref + isi) + Phi);
phase_sensitivity = 0.5 + 0.5 * phase_term;  % range [0,1]

% Drift rate (positive for deviant, negative for standard)
if Ua == 1  % deviant
    nu = (A0 / S) * phase_sensitivity;   % positive
else        % standard
    nu = -(A0 / S) * 0.5 * phase_sensitivity;   % negative, asymmetric
end

% Probability of responding "deviant" (choice = 0)
% We must map Ua to choice: suppose deviant -> correct response is 0, standard -> correct is 1.
% Then probability of correct = 1/(1+exp(-2*|nu|*gam/sig^2)) with sign of nu.
% For a binary response, we need p(choice=1). Let's define:
%   if Ua==1 (deviant), correct response is 0; if Ua==0 (standard), correct response is 1.
% So p(choice=1) = probability of responding "standard".
p_standard = 1 / (1 + exp(2*nu*gam/sig^2));  % because nu positive for deviant gives exp(positive) -> p_standard small.
% Check: when nu > 0, exp(2*nu*gam/sig^2) > 1, so p_standard < 0.5. Good.

% Expected RT (simplified deterministic formula)
abs_nu = abs(nu) + eps;  % avoid division by zero
mean_RT = t0 + gam / abs_nu;   % very crude approximation, the higher the drift rate the smaller the right term is -> the faster I make my decision

gx = [p_standard; mean_RT];

