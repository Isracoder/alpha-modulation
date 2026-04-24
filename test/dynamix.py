"""
simulate_dynamax.py
===================
Dynamax equivalent of VBA_simulate for the M3 (gamma-based Bayesian learner)
+ G3 (DDM-based choice/RT observer) model.

Mirrors the MATLAB call:
    [y, x, x0, eta, e, u] = VBA_simulate(nt, fname, gname, Ptheta, Pphi, U,
                                          alpha, sigma, options, Sx0)

Key design decisions
--------------------
* VBA_simulate runs the evolution function f deterministically when alpha/sigma
  are very large (≈ Inf).  We replicate this: the state noise covariance Q is
  set to a near-zero matrix (1e-6 * I) so the trajectory is effectively
  deterministic, matching MATLAB's "high precision = no noise" convention.
* The observation noise for Gaussian outputs (RT, amplitude, phase) is also set
  to a small diagonal covariance (controlled by `sigma`).
* The Bernoulli choice output (gx[0]) is NOT Gaussian, so it is handled outside
  the NLGSSM emission model and sampled directly in the g_Audio_Resp equivalent.
* Dynamax's NonlinearGaussianSSM.sample() drives the forward pass; we wrap it
  so it accepts the same argument shapes as the MATLAB code.

Dependencies
------------
    pip install dynamax jax jaxlib numpy scipy
"""

import jax
import jax.numpy as jnp
import jax.random as jr
import numpy as np
from dynamax.nonlinear_gaussian_ssm.models import (NonlinearGaussianSSM,
                                                   ParamsNLGSSM)
from gen_input import generate_input
from jax import lax

# ---------------------------------------------------------------------------
# 1.  f_Audio_H3_gamma  (evolution function, M3 model)
# ---------------------------------------------------------------------------


def f_Audio_H3_gamma(x_states: jnp.ndarray,
                     u_input: jnp.ndarray,
                     theta_params: jnp.ndarray) -> jnp.ndarray:
    """
    Dynamax-compatible evolution function for the M3 gamma-precision model.

    State vector x (8-dim):
        0: mu1        – posterior mean ISI
        1: log(pi1)   – posterior log-precision ISI
        2: mu1_prior  – prior mean  (= previous mu1)
        3: log_pi1_prior – prior log-precision
        4: log(ppred) – predictive log-precision
        5: time_accum – elapsed time accumulator (seconds)
        6: log(alpha) – gamma shape  (log-space for positivity)
        7: log(beta)  – gamma scale  (log-space for positivity)

    Parameters theta (2-dim):
        0: log(pU)  – sensory precision (log-space)
        1: log(pX)  – prior precision   (unused here; replaced by gamma)

    Input u (3-dim):
        0: Uv   – visual trial flag
        1: Ua   – auditory std(0)/dev(1) flag
        2: isi  – inter-stimulus interval (ms)
    """
    mu_prior = x_states[0]
    prec_prior = jnp.exp(x_states[1])
    alpha_pX = jnp.exp(x_states[6])
    beta_pX = jnp.exp(x_states[7])
    pU = jnp.exp(theta_params[0])
    isi = u_input[2]

    # Dynamic pX from gamma parameters (mean = alpha/beta)
    current_pX = alpha_pX / (beta_pX + 1e-8)
    # Safety: if alpha <= 1 fallback to 2 (matches MATLAB logic)
    pX = jnp.where(alpha_pX <= 1.0, 2.0, current_pX)

    # Bayesian update
    PE = isi - mu_prior
    ratio = (prec_prior * pX) / (prec_prior + pX)
    prec = pU + ratio
    tau = pU / prec
    mu_new = mu_prior + tau * PE

    ppred1 = (pU * prec) / (pU + prec)
    ppred = (pX * ppred1) / (pX + ppred1)

    # Inverse-gamma update for pX with forgetting
    var_known = 1.0 / pU + 1.0 / prec_prior
    delta = jnp.maximum(0.0, PE**2 - var_known)

    lambda_ = 0.25
    eta = 0.01
    alpha_init = 2.0
    beta_init = 0.25

    alpha_new = lambda_ * alpha_pX + (1 - lambda_) * (alpha_init + 0.5 * eta)
    beta_new = lambda_ * beta_pX + \
        (1 - lambda_) * (beta_init + 0.5 * delta * eta)

    fx = jnp.array([
        mu_new,                          # 0: posterior mean
        jnp.log(prec),                   # 1: posterior log-precision
        # 2: prior mean  = posterior mean (for next step)
        mu_new,
        # 3: prior log-precision (carry forward)
        x_states[1],
        jnp.log(ppred),                  # 4: predictive log-precision
        x_states[5] + isi / 1000.0,      # 5: time accumulator (s)
        jnp.log(alpha_new),              # 6: log alpha
        jnp.log(beta_new),               # 7: log beta
    ])
    return fx


# ---------------------------------------------------------------------------
# 2.  g_Audio_Resp  (observation function, G3 model)
#     Returns the *deterministic* mean prediction only.
#     Mixed discrete/continuous outputs are handled by the simulator below.
# ---------------------------------------------------------------------------

def g_Audio_Resp_mean(x_states: jnp.ndarray,
                      u_input: jnp.ndarray,
                      phi_params: jnp.ndarray,
                      phi_opt: float = 0.0,
                      n_mc: int = 1000,
                      dt: float = 1e-2,
                      rng_key: jnp.ndarray = None) -> dict:  # type: ignore
    """
    Pure-Python (numpy) observation function matching g_Audio_Resp.m.
    Returns a dict with keys: 'choice', 'rt', 'amplitude', 'phase'.

    This is intentionally NOT fully JAX-traced because the DDM while-loop
    has a variable number of steps; we run it in numpy for simulation.
    For inversion you would replace this with an analytic approximation.

    Parameters phi (5-dim):
        0: power (alpha amplitude baseline)
        1: f     (oscillation frequency)
        2: sig   (DDM noise)
        3: gam   (decision threshold)
        4: t0    (non-decision time offset)
    """
    x = np.array(x_states)
    u = np.array(u_input)
    phi = np.array(phi_params)

    mu = x[2]           # prior mean ISI
    pred_prec = np.exp(x[4])   # predictive precision
    Tref = x[5]           # elapsed time

    power = phi[0]
    f = phi[1]
    sig = phi[2]
    gam = phi[3]
    # t0  = phi[4]             # non-decision time (available if needed)

    Uv = u[0]                 # visual trial flag
    Ua = u[1]                 # std=0 / dev=1
    isi = u[2]

    S = 0.5 * np.log(2 * np.pi * np.e / (pred_prec + 1e-8))
    Phi = phi_opt - 2 * np.pi * f * (Tref + mu)
    phase_term = np.sin(2 * np.pi * f * (Tref + isi) + Phi)
    phase_sensitivity = 0.2 * (1 + phase_term)

    amplitude = power / (S + 1e-8)
    phase_out = 2 * np.pi * f * (Tref + isi) + Phi

    if Uv == 0:
        return dict(choice=0.0, rt=0.0, amplitude=amplitude, phase=phase_out)

    # Drift rate
    if Ua == 1:     # deviant
        nu = (power / (S + 1e-8)) * phase_sensitivity
    else:           # standard
        nu = -(power / (S + 1e-8)) * 0.2 * phase_sensitivity

    # Monte-Carlo DDM
    rng = np.random.default_rng(None if rng_key is None else int(rng_key[0]))
    choices = np.zeros(n_mc)
    rts = np.zeros(n_mc)

    for i in range(n_mc):
        z = 0.0
        t = 0
        while True:
            z += nu * dt + sig * np.sqrt(dt) * rng.standard_normal()
            t += 1
            if z >= gam:
                choices[i] = 1.0
                rts[i] = t * dt
                break
            elif z <= -gam:
                choices[i] = 0.0
                rts[i] = t * dt
                break

    p1 = np.mean(choices)
    choice = float(p1 > 0.5)
    rt = float(np.mean(rts))

    return dict(choice=choice, rt=rt, amplitude=amplitude, phase=phase_out)


# ---------------------------------------------------------------------------
# 3.  VBA_simulate equivalent:  simulate_subject()
# ---------------------------------------------------------------------------

def simulate_subject(U: np.ndarray,
                     theta: np.ndarray,
                     phi: np.ndarray,
                     x0: np.ndarray,
                     alpha: float = 1e6,
                     sigma: float = 1e6,
                     phi_opt: float = 0.0,
                     skip_first: bool = True,
                     rng_seed: int = 0) -> dict:
    """
    Forward simulation equivalent to VBA_simulate() for the M3/G3 model.

    Parameters
    ----------
    U       : (3, T) input array   [Uv, Ua, isi]  — one column per trial
    theta   : (2,) evolution parameters [log(pU), log(pX)]
    phi     : (5,) observation parameters [power, f, sig, gam, t0]
    x0      : (8,) initial state vector
    alpha   : state noise precision  (large → deterministic, matches VBA default)
    sigma   : obs   noise precision  (large → deterministic)
    phi_opt : phase offset for oscillator (PhiOpt in MATLAB)
    skip_first : if True, clamp state at t=0 to x0 without update (matches options.skipf(1)=1)
    rng_seed   : random seed for reproducibility

    Returns
    -------
    dict with keys:
        'y'     : (4, T) observed outputs [choice, rt, amplitude, phase]
        'x'     : (8, T) hidden state trajectory
        'x0'    : (8,)   initial state used
        'theta' : parameters used
        'phi'   : parameters used
        'alpha' : alpha used
        'sigma' : sigma used
    """
    T = U.shape[1]
    x = np.zeros((len(x0), T))
    y = np.zeros((4, T))
    rng = np.random.default_rng(rng_seed)

    # State noise std (very small when alpha is large)
    state_std = 1.0 / np.sqrt(alpha) if alpha < 1e9 else 0.0
    # Obs noise std for Gaussian outputs (rt, amplitude, phase)
    obs_std = 1.0 / np.sqrt(sigma) if sigma < 1e9 else 0.0

    x_prev = np.array(x0, dtype=float)

    for t in range(T):
        u_t = U[:, t]

        # --- Evolution step ---
        if t == 0 and skip_first:
            # VBA skipf(1) = 1: keep initial state, no evolution noise
            x_t = x_prev.copy()
        else:
            # Deterministic evolution (+ optional tiny noise)
            x_t = np.array(f_Audio_H3_gamma(
                jnp.array(x_prev),
                jnp.array(u_t),
                jnp.array(theta)
            ))
            if state_std > 0:
                x_t += state_std * rng.standard_normal(len(x0))

        x[:, t] = x_t

        # --- Observation step ---
        # Skip no-go trials (Uv == 0) — observations still computed but zeroed by g
        obs = g_Audio_Resp_mean(
            (x_t), u_t, phi,
            phi_opt=phi_opt,
            rng_key=rng.integers(0, 2**31, size=2)
        )

        y[0, t] = obs['choice']
        y[1, t] = obs['rt'] + \
            (obs_std * rng.standard_normal() if obs_std > 0 else 0.0)
        y[2, t] = obs['amplitude'] + \
            (obs_std * rng.standard_normal() if obs_std > 0 else 0.0)
        y[3, t] = obs['phase'] + \
            (obs_std * rng.standard_normal() if obs_std > 0 else 0.0)

        x_prev = x_t

    return dict(y=y, x=x, x0=x0, theta=theta, phi=phi, alpha=alpha, sigma=sigma)


# ---------------------------------------------------------------------------
# 4.  Multi-subject simulate() wrapper (matches MATLAB simulate() subfunction)
# ---------------------------------------------------------------------------

def simulate(U: np.ndarray,
             Ns: int,
             theta: np.ndarray,
             phi: np.ndarray,
             x0: np.ndarray,
             alpha: float = 1e6,
             sigma: float = 1e6,
             phi_opt: float = 0.0,
             base_seed: int = 0) -> tuple[list, list]:
    """
    Run Ns subjects through simulate_subject().

    Returns
    -------
    Y           : list of (4, T) arrays, one per subject
    SimulParams : list of dicts, one per subject
    """
    Y = []
    SimulParams = []

    for k in range(Ns):
        print(f"Simulating subject {k + 1}/{Ns}")
        result = simulate_subject(
            U, theta, phi, x0,
            alpha=alpha, sigma=sigma,
            phi_opt=phi_opt,
            rng_seed=base_seed + k
        )
        Y.append(result['y'])
        SimulParams.append(result)

    return Y, SimulParams


# ---------------------------------------------------------------------------
# 5.  Thin Dynamax wrapper (optional, for inference later)
#     Sets up a NonlinearGaussianSSM whose dynamics function = f_Audio_H3_gamma
#     and whose emission function is the *linear part* of g_Audio_Resp
#     (choice is excluded; only RT/amplitude/phase are modelled as Gaussian).
# ---------------------------------------------------------------------------

def build_dynamax_model(theta: np.ndarray,
                        phi: np.ndarray,
                        x0: np.ndarray,
                        noise_level: float = 1e-6) -> tuple:
    """
    Build a Dynamax NonlinearGaussianSSM for the M3 model.

    The Gaussian emission covers outputs [rt, amplitude, phase] (3-dim).
    Choice (Bernoulli) must be handled separately.

    Returns
    -------
    model  : NonlinearGaussianSSM
    params : ParamsNLGSSM
    """
    state_dim = len(x0)   # 8
    emission_dim = 3         # rt, amplitude, phase  (no Bernoulli choice)
    model = NonlinearGaussianSSM(state_dim, emission_dim)

    _theta = jnp.array(theta)
    _phi = jnp.array(phi)

    def dynamics_fn(z, u):
        return f_Audio_H3_gamma(z, u, _theta)

    def emission_fn(z, u):
        """Linearised / deterministic part of g_Audio_Resp for Gaussian outputs."""
        pred_prec = jnp.exp(z[4])
        Tref = z[5]
        mu = z[2]
        power = _phi[0]
        f_osc = _phi[1]
        S = 0.5 * jnp.log(2 * jnp.pi * jnp.e / (pred_prec + 1e-8))
        Phi = -2 * jnp.pi * f_osc * (Tref + mu)
        isi = u[2]
        phase_out = 2 * jnp.pi * f_osc * (Tref + isi) + Phi
        amplitude = power / (S + 1e-8)
        rt_placeholder = jnp.zeros(())   # RT has no closed-form; use 0 as mean
        return jnp.array([rt_placeholder, amplitude, phase_out])

    params = ParamsNLGSSM(
        initial_mean=jnp.array(x0),
        initial_covariance=noise_level * jnp.eye(state_dim),
        dynamics_function=dynamics_fn,
        dynamics_covariance=noise_level * jnp.eye(state_dim),
        emission_function=emission_fn,
        emission_covariance=noise_level * jnp.eye(emission_dim),
    )

    return model, params


# ---------------------------------------------------------------------------
# 6.  Quick smoke-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import matplotlib.pyplot as plt

    # --- Default parameters matching simul_data.m ---
    pU = np.log(16)
    pX = np.log(8)
    mu0 = 450.0

    x0 = np.array([mu0, np.log(16), mu0, np.log(16), np.log(16), 0.0,
                   np.log(2), np.log(0.25)])
    theta = np.array([pU, pX])
    phi = np.array([5.0, 10.0, 0.1, 1.0, 0.0])   # G3 defaults

    # --- Minimal synthetic input sequence (predictable, 50 trials) ---
    # T = 50
    # U_syn = np.zeros((3, T))
    # U_syn[0, :] = 1                       # all visual
    # U_syn[1, 1::2] = 1                    # alternating dev/std
    # U_syn[2, :] = 500                     # constant ISI = 500 ms
    U_syn = np.array(generate_input())

    # Skip no-go (Uv==0) — none here, so skipf only applies to t=0
    Y, SimulParams = simulate(U_syn, Ns=2, theta=theta, phi=phi, x0=x0,
                              alpha=1e6, sigma=1e6, base_seed=42)

    # --- Plot state trajectory for subject 1 ---
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), sharex=True)

    x_traj = SimulParams[0]['x']
    axes[0].plot(x_traj[0], label='mu1 (posterior mean ISI)')
    axes[0].axhline(500, color='k', linestyle='--',
                    linewidth=0.8, label='true ISI')
    axes[0].set_ylabel('ISI mean (ms)')
    axes[0].legend(fontsize=8)

    axes[1].plot(np.exp(x_traj[1]), label='prec1 (posterior precision)')
    axes[1].set_ylabel('Precision')
    axes[1].legend(fontsize=8)

    axes[2].plot(Y[0][0], 'o-', label='choice')
    axes[2].plot(Y[0][1], 's-', label='RT (s)')
    axes[2].set_ylabel('Observables')
    axes[2].set_xlabel('Trial')
    axes[2].legend(fontsize=8)

    plt.suptitle('M3/G3 Simulation — Dynamax equivalent of VBA_simulate')
    plt.tight_layout()
    plt.savefig('/mnt/user-data/outputs/simulate_dynamax_demo.png', dpi=150)
    plt.close()
    print("Demo plot saved.")

    # --- Build the Dynamax model object (for future inference) ---
    model, params = build_dynamax_model(theta, phi, x0)
    print(
        f"\nDynamax model built: state_dim={model.state_dim}, emission_dim={model.emission_dim}")
    print("Ready for EKF/UKF inference with dynamax.nonlinear_gaussian_ssm.extended_kalman_filter()")
