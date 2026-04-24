# import arviz as az
import numpy as np
import pymc as pm
import pytensor
import pytensor.tensor as pt


def custom_evolution(x_tm1, theta, t):
    """
    Custom evolution function f(x_t-1, theta, t)
    Equivalent to VBA's f_fname
    """
    # Example: Logistic growth with process noise
    r, K = theta
    x_t = x_tm1 + r * x_tm1 * (1 - x_tm1 / K)
    return x_t


def custom_observation(x_t, phi, t):
    """
    Custom observation function g(x_t, phi, t)
    Equivalent to VBA's g_fname
    """
    # Example: Quadratic observation with measurement scaling
    a, b = phi
    y_t = a * x_t + b * x_t**2
    return y_t


def simulate_state_space(n_t, f_func, g_func, theta, phi, alpha, sigma, x0, rng=None):
    """
    Simulate data from custom state-space model
    Similar to VBA_simulate output: (y, x, eta, e)
    """
    if rng is None:
        rng = np.random.default_rng(42)

    # Pre-allocate arrays
    x = np.zeros(n_t + 1)
    eta = np.zeros(n_t)
    y = np.zeros(n_t)
    e = np.zeros(n_t)

    # Initial state
    x[0] = x0

    # Simulation loop
    for t in range(n_t):
        # Evolution: x_t = f(x_{t-1}, theta) + eta_t
        x[t] = f_func(x[t-1] if t > 0 else x0, theta, t)
        eta[t] = rng.normal(0, 1.0/np.sqrt(alpha))
        x[t] += eta[t]

        # Observation: y_t = g(x_t, phi) + e_t
        y[t] = g_func(x[t], phi, t)
        e[t] = rng.normal(0, 1.0/np.sqrt(sigma))
        y[t] += e[t]

    return y, x[1:], x0, eta, e


# Set parameters
n_t = 100
theta_true = [0.5, 20.0]  # [r, K] for logistic growth
phi_true = [1.0, 0.1]      # [a, b] for quadratic observation
alpha_true = 10.0          # Precision of innovations
sigma_true = 100.0         # Precision of measurement error
x0_true = 0.5

# Simulate data
y_obs, x_true, _, eta_true, e_true = simulate_state_space(
    n_t, custom_evolution, custom_observation,
    theta_true, phi_true, alpha_true, sigma_true, x0_true
)


def state_space_dist(theta_r, theta_K, phi_a, phi_b, alpha, sigma, x0, n_steps):
    """Custom distribution for state-space model"""

    def step(x_tm1, theta_r, theta_K, phi_a, phi_b, alpha, sigma):
        # Evolution (f_fname)
        x_t = x_tm1 + theta_r * x_tm1 * (1 - x_tm1 / theta_K)

        # Stochastic innovation
        innovation = pm.Normal.dist(mu=0.0, sigma=1.0/pt.sqrt(alpha))
        x_t_noisy = x_t + innovation

        # Observation (g_fname)
        y_t = phi_a * x_t_noisy + phi_b * x_t_noisy**2

        # Measurement error
        measurement_error = pm.Normal.dist(mu=0.0, sigma=1.0/pt.sqrt(sigma))
        y_t_noisy = y_t + measurement_error

        return (x_t_noisy, y_t_noisy), collect_default_updates([x_t_noisy, y_t_noisy])

    # Run the scan
    x0_tensor = pt.as_tensor_variable(x0)
    ([x_seq, y_seq], updates) = pytensor.scan(
        fn=step,
        outputs_info=[{"initial": x0_tensor}, None],
        non_sequences=[theta_r, theta_K, phi_a, phi_b, alpha, sigma],
        n_steps=n_steps,
        strict=True
    )

    return y_seq  # Return observations


# PyMC model for inference
with pm.Model() as model:
    # Priors over parameters
    theta_r = pm.HalfNormal('theta_r', sigma=0.5)
    theta_K = pm.Normal('theta_K', mu=20.0, sigma=5.0)
    phi_a = pm.Normal('phi_a', mu=1.0, sigma=0.5)
    phi_b = pm.Normal('phi_b', mu=0.0, sigma=0.5)
    alpha = pm.Gamma('alpha', alpha=2.0, beta=1.0)
    sigma = pm.Gamma('sigma', alpha=2.0, beta=1.0)
    x0 = pm.Normal('x0', mu=0.5, sigma=0.5)

    # Likelihood using CustomDist
    y_obs_data = pm.ConstantData('y_obs', y_obs)
    pm.CustomDist(
        'y',
        theta_r, theta_K, phi_a, phi_b, alpha, sigma, x0,
        dist=state_space_dist,
        observed=y_obs_data
    )

    # Sample posterior
    idata = pm.sample(chains=2, cores=2, random_seed=42)
