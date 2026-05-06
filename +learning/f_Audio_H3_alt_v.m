function [fx] = f_Audio_H3_alt_v(x_states, theta_params, u_input, ~)
    % x_states:
    % 1 = mu1 (posterior mean ISI)
    % 2 = log(pi1) (posterior precision ISI)
    % 3 = mu1 prior         (same as x1)
    % 4 = pi1 prior log     (same as x2)
    % 5 = log(predictive precision)
    % 6 = time accumulator
    % 7 = log(v_extra)      (extra variance = 1/pX)  <-- changed
    % 8 = px for plotting
    fx = zeros(size(x_states));

    % ---------- fixed parameters ----------
    pU       = exp(theta_params(1));    % sensory precision (known)
    lambda_v = 0.9;                     % forgetting factor for v_extra (0.9 ≈ 10-trial memory)
    v_min    = 1e-6;                    % floor to avoid 1/0
    pX_max   = 1e4;                     % optional cap on pX (prevents lock-up)

    % ---------- unpack state ----------
    mu_prior   = x_states(1);
    prec_prior = exp(x_states(2));      % π_prior from previous trial
    v_extra    = exp(x_states(7));      % current estimate of 1/pX

    % ---------- compute current pX ----------
    pX = 1 / max(v_extra, v_min);
    pX = min(pX, pX_max);

    % ---------- Kalman‑like update for μ ----------
    ratio = (prec_prior * pX) / (prec_prior + pX);   % harmonic mean
    prec  = pU + ratio;
    tau   = pU / prec;
    isi   = u_input(3);
    PE    = isi - mu_prior;
    mu    = mu_prior + tau * PE;

    % posterior precision for next step
    prec_post = prec;   % posterior precision after this observation

    % predictive precision (optional, kept for compatibility)
    ppred1 = (pU * prec) / (pU + prec);
    ppred  = (pX * ppred1) / (pX + ppred1);

    % ---------- store updated μ, precision, prior ----------
    fx(1) = mu;
    fx(2) = log(prec_post);
    fx(3) = mu;                    % prior mean for next trial = current posterior
    fx(4) = log(prec_post);        % prior precision for next trial
    fx(5) = log(ppred);
    fx(6) = x_states(6) + isi/1000;   % time in seconds (ISI assumed in ms)

    % ---------- update v_extra (1/pX) with forgetting ----------
    var_known = 1/pU + 1/prec_prior;          % known part of prediction error variance
    v_inst    = max(0, PE^2 - var_known);     % instantaneous extra variance estimate

    % leaky integrator
    v_extra_new = lambda_v * v_extra + (1 - lambda_v) * v_inst;
    v_extra_new = max(v_extra_new, v_min);    % keep away from log(0)

    fx(7) = log(v_extra_new);
    fx(8) = log(pX) ;% stored to plot

    % optional debug print
    if (x_states(6) <= 2.0 || (x_states(6) >= 30.5 && x_states(6) <= 32))
        fprintf('\nt=%.2f: PE=%.3f, var_known=%.3f, v_inst=%.3f, v_extra=%.3f, pX=%.3f, mu=%.3f\n', ...
            fx(6), PE, var_known, v_inst, v_extra_new, pX, mu);
    end
end