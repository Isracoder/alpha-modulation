function [fx] = f_Audio_H4_gamma_oscillator(x_states,theta_params,u_input,~)
    % x_states:
    % 1 = mu1 (posterior mean ISI)
    % 2 = log(pi1) (posterior precision ISI)
    % 3 = mu1 prior (same as x1)
    % 4 = pi1 prior (same as x2)
    % 5 = predictive precision (same as x2 in code)
    % 6 = time accumulator
    % 7 = mu2 (posterior mean of log volatility) (for pX)
    % 8 = log(pi2) (posterior precision of volatility)
    fx = zeros(size(x_states));

    % fx(1) = x_states(1);                 % posterior mean -> prior mean for next
    fx(1) = x_states(1);
    fx(2) = exp(x_states(2)); % x2, 4, and 5 need exp since they were previously log transformed , assumed 16
    fx(3) = x_states(1);                 % prior mean = previous posterior mean
    fx(4) = (x_states(2));                 % prior precision = previous posterior precision

    mu_prior = x_states(1);           % prior mean (previous posterior mean)
    prec_prior = exp(x_states(2));    % prior precision (previous posterior precision)

    % Parameters (all in natural space, but kept positive via exp)
    pU    = exp(theta_params(1));        % sensory precision (fixed)

    % pX parameters (inverse gamma)
    alpha_pX = exp(x_states(7));  % shape parameter (log transform for positivity)
    beta_pX  = exp(x_states(8));   % scale parameter

    % ----- Current pX from inverse‑gamma belief -----
    % Posterior mean of σ² = b/(a-1)  (for a>1)
    % So pX = 1 / mean(σ²) = (a-1)/b
    % current_pX = (alpha_pX - 1) / beta_pX;
    % current_pX = beta_pX / ((alpha_pX - 1) + eps) ;
    current_pX = alpha_pX / (beta_pX + eps) ;


    % Safety (avoid a<=1)
    if alpha_pX <= 1
        disp("*")
        current_pX = 2;  % fallback
    end
    % current_pX = beta_pX/(alpha_pX - 1);  % expected precision
    % current_pX = exp(beta_pX , alpha_pX) / gamma(alpha_pX) * exp((1/prior_pX), alpha_pX -1) * exp(-beta_pX / (1/prior_pX))
    % fprintf('Current px: %d\n', current_pX);

    % Use dynamic pX instead of fixed parameter
    pX = current_pX;  % replaces exp(theta_params(2))
    isi = u_input(3) ;
    PE = isi - mu_prior;           % deviation from expectation

    % Level 1 update (exactly as before, but with pX now a variable)
    % --- Bayesian mean update (unchanged logic) ---
    ratio = (prec_prior * pX) / (prec_prior + pX);   % harmonic mean of precisions
    prec = pU + ratio;                         % base posterior precision (if no error modulation)
    tau = pU / prec;                           % learning rate
    mu = mu_prior + tau * PE;                    % new posterior mean
    ppred1 = (pU*prec) / (pU + prec);
    ppred = (pX*ppred1) / (pX + ppred1);

    % if (x_states(6) <= 2.5)
    %     fprintf('\nratio=%d: prec=%.3f, tau=%.3f, isi=%.3f, mu_prior=%.3f, new_mu=%.3f, ppred1=%.2f, pU=%.2f , pX=%.2f ,  ppred=%.2f\n', ...
    %         ratio, prec, tau,isi, mu_prior, mu, ppred1 , pU, pX, ppred);
    % end

    % Store updated parameters
    fx(1) = mu;
    % fx(2) = log(ppred);  % predictive precision , have this or other ?
    fx(2) = log(prec);
    fx(5) = log(ppred);  % predictive precision
    fx(6) = x_states(6) + isi/1000;

    var_known = 1/pU + 1/prec_prior ;
    delta = max(0, PE^2 - var_known);
    % Parameters
    lambda = 0.25;      % forgetting factor (close to 1 = long memory)
    eta = 0.01;         % initially 0.01, learning rate (can be merged into lambda) or equation directly, weirdly increasing gives more disappearance of peaks/blocs pattern in pp, as if i'm overstepping and then missing the answer
    alpha_initial = 2;
    beta_initial = 0.25 ;

    % Update with forgetting so that I can recover after initial shocks and decrease
    alpha_new = lambda * alpha_pX + (1-lambda) * (alpha_initial + 0.5 * eta);
    % alpha_new = alpha_pX + 1 ;
    beta_new  = lambda * beta_pX  + (1-lambda) * (beta_initial + 0.5 * delta * eta);

    % if (fx(6) <= 5.0)
    %     fprintf('\nt=%d: e=%.3f, var_known=%.3f, delta=%.3f, a=%.2f, b=%.2f, pX=%.3f, mu=%.3f \n', ...
    %         fx(6), PE, var_known, delta, alpha_new, beta_new, pX , mu);
    % end

    fx(7) = log(alpha_new);  % store in log space
    fx(8) = log(beta_new);


    %% Kuramoto oscillator dynamics

    % dt = inF.dt;   % time step between successive calls
    % dt = 0.01 ;

    precision = ppred ;

    x_osc = x_states(9);
    y_osc = x_states(10);

    % task_modulation = 0.4 * sinpi(2 *pi * 0.1 * (PE^2)) ;

    % return base_freq * (1 + task_modulation)

    frequency = 10;            % Hz
    % omega = frequency * 2 * pi;
    % lambda = 1.0 * precision ;
    K = 1.0;                   % coupling (ignore rn as N is 1)
    % K = 2.0 ;
    % omega = frequency * 2 * pi  * (1 + task_modulation) ;
    % lambda = 1.0 * precision * (0.8 + task_modulation);  % precision modulates amplitude, should I keep precision as is or think of weighing it somehow,
    % lambda may be seen referred to as mu or bifurcation param controlling stability

    [x , y] = hopf(1 , K , precision, frequency, [x_osc, y_osc]) ;

    fx(9) = x;
    fx(10) = y;

    % Hopf dynamics in Cartesian coordinates
    % r2 = x_osc^2 + y_osc^2;
    % dx_osc_dyn = (lambda - r2) * x_osc - omega * y_osc;
    % dy_osc_dyn = (lambda - r2) * y_osc + omega * x_osc;

    % dx_osc = x_osc + dx_osc_dyn * dt;
    % dy_osc = y_osc + dy_osc_dyn * dt;

    % fx(9) = dx_osc;
    % fx(10) = dy_osc;


    % PHASE MODULATION ATTEMPT
    % phase_value = 2*pi*delta;
    % Compute target phase for this moment
    % phi_target = -2*pi * PE / mu; % should mu here be expected isi at this trial or next one ?
    % phi_target = mod(phi_target, 2*pi);  % wrap to [0,2π)
    % x_phase_change  = cos(phi_target) ; % can multiple by amplitude here as well
    % y_phase_change = sinpi(phi_target) ;

    % dx_osc_dyn = dx_osc_dyn + K * (x_phase_change  - x_osc) ;
    % dy_osc_dyn = dy_osc_dyn + K * (y_phase_change  - y_osc) ;



    % if (x_states(6) <= 2.5 || x_states(6) >= 30.5)
    %     fprintf('\n\n PRECISION=%d: AMPLITUDE=%.3f, last X = %.3f, last Y= %.3f, dx = %.3f, dy=%.3f \n\n', ...
    %         precision,  (dx_osc^2 + dy_osc^2), x_osc , y_osc, dx_osc, dy_osc);
    % end


end

function [x_final , y_final] = hopf(N , K , precision, frequency, state, time, dt)

    %% Kuramoto model in Cartesian coordinates (Hopf oscillators)
    % clear; clc;
    arguments
        N = 1 ;
        K = 1 ;
        precision = 1 ;
        frequency = 10 ;
        state = [cos(2 * pi*0.5); sinpi(2*pi*0.5)]; % replaced rand with 0.5
        time = 10 ; % should coordinate to make sure that time between trial t and t+1 is in line with this simulation time and trial period
        dt = 0.01 ;
        % dt = 0.001 ;
    end

    lambda = 1.0 * (precision) ; % the higher the precision the higher the amplitude,
    omega = frequency * 2 * pi;   % natural frequencies, def = 2 pi
    tspan = 0:dt:time;


    % -----------------------
    % Integrate
    % -----------------------
    opts = odeset('RelTol',1e-6,'AbsTol',1e-8);
    [t, sol] = ode45(@(t,s) hopf_cartesian(t,s,N,omega,K,lambda), ...
        tspan, state, opts);

    x = sol(:,1:N)';
    y = sol(:,N+1:end)';

    % disp(size(sol))
    % disp(size(x))
    % disp(numel(x))
    % disp(size(y))

    x_final = x(1, end) ; % take only last timepoint, x is 1 * 1000 if 1000 is num of simulation-points
    y_final = y(1, end)  ;% y same dimensions as x
end

function dsdt = hopf_cartesian(~, s, N, omega, K, lambda)

    x = s(1:N);
    y = s(N+1:end);

    r2 = x.^2 + y.^2;

    % can manipulate lambda and multiply it by precision

    dx = (lambda - r2).*x - omega.*y;
    dy = (lambda - r2).*y + omega.*x;

    % Kuramoto-style mean-field coupling
    dx = dx + K*(mean(x) - x);
    dy = dy + K*(mean(y) - y);

    dsdt = [dx; dy];
end



% -----------------------
% Phase + amplitude + order parameter
% -----------------------
% theta = atan2(y, x);
% amplitude = x.^2 + y.^2;
% R = abs(mean(exp(1i*theta),1));
% phase = theta' ;
% amp = amplitude ;
