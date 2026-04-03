import matplotlib.pyplot as plt
import numpy as np
from scipy.integrate import solve_ivp


def hopf_cartesian(t, s, N, precision_func, omega, K, lam):
    x = s[:N]
    y = s[N:]
    r2 = x**2 + y**2

    # Array of precision values for each oscillator
    prec = precision_func(t, N)

    # Compute individual parameters based on precision
    # Higher precision -> higher amplitude and frequency
    # lam_vals = base_lam * prec        # Amplitude control
    # omega_vals = base_omega * prec    # Frequency control

    # Get current parameter values from functions
    # current_omega = omega(t) * prec
    # current_lam = lam(t) * prec
    # current_K = K(t)
    current_K = 1.0
    current_lam = 1.0
    current_omega = 10 * 2 * np.pi

    dx = (current_lam - r2)*x - current_omega*y
    dy = (current_lam - r2)*y + current_omega*x

    dx += current_K*(np.mean(x) - x)
    dy += current_K*(np.mean(y) - y)

    return np.concatenate([dx, dy])
    # % idea to manipulate phase is :

    # later have this be parameter that influences oscillations
    # tried using random value but computation was slow didn't finish
    # phase_value = 2*np.pi * 5
    # phase_input = phase_value
    # # can multiple by amplitude here as well
    # x_phase_change = np.cos(phase_input)
    # y_phase_change = np.sin(phase_input)
    # dx = dx + K * (x_phase_change - x)
    # dy = dy + K * (y_phase_change - y)


def hopf_oscillator(amp_scaling=1.0, num_oscillators=1, frequency_multiplier=1.0):
    # if precision is None:
    #     print('no inputs provided, generating with default params')
    #     precision = 1
    # else:
    print(
        f'using provided values of : (precision/amp_scaling {amp_scaling}) (num_oscillators {num_oscillators}) (frequency_multiplier {frequency_multiplier})')

    # Parameters
    N = num_oscillators

    K = 1.0
    lam = 1.0 * amp_scaling  # having it negative seems to make it die out
    # default of 2pi does one every second
    omega = frequency_multiplier * 2 * np.pi

    T = 10  # previously was 30 but I shortened
    dt = 0.001  # default 0.001, increasing to 0.1 doesn't affect frequency but makes amplitude less dense and circle more pentagon shaped
    tspan = (0, T)
    t_eval = np.arange(0, T+dt, dt)

    # Initial conditions
    theta0 = 2*np.pi*np.random.rand(N)
    r0 = 1

    x0 = r0 * np.cos(theta0)
    y0 = r0 * np.sin(theta0)

    state0 = np.concatenate([x0, y0])

    # tspan = (0, 100)  # 100 seconds simulation
    # t_eval = np.linspace(0, 100, 5000)

    # Integrate with time-dependent parameters
    sol = solve_ivp(hopf_cartesian, tspan, state0,
                    args=(N, precision_t, omega_t, K_t, lam_t),
                    t_eval=t_eval, rtol=1e-6, atol=1e-8)

    # Integrate
    # sol = solve_ivp(hopf_cartesian, tspan, state0, args=(N, omega, K, lam),
    #                 t_eval=t_eval, rtol=1e-6, atol=1e-8)

    t = sol.t
    x = sol.y[:N, :]
    y = sol.y[N:, :]

    # Phase + amplitude + order parameter
    theta = np.arctan2(y, x)
    amplitude = x**2 + y**2
    R = np.abs(np.mean(np.exp(1j*theta), axis=0))

    # Plot
    plt.figure(figsize=(12, 3))

    plt.subplot(1, 4, 1)
    plt.plot(t, theta.T, linewidth=0.8)
    plt.xlabel('Time')
    plt.ylabel('Phase')

    plt.subplot(1, 4, 2)
    plt.plot(t, amplitude.T, 'k', linewidth=2)
    plt.xlabel('Time')
    plt.ylabel('Amplitude')

    plt.subplot(1, 4, 3)
    plt.plot(t, x.T, 'k', linewidth=2)
    plt.plot(t, y.T, 'b', linewidth=2)
    plt.xlabel('Time')
    plt.ylabel('x(t), y(t)')

    plt.subplot(1, 4, 4)  # default oscillator plot
    plt.plot(x.T, y.T, 'k', linewidth=2)
    plt.xlabel('x(t)')
    plt.ylabel('y(t)')
    plt.axis((-1.0, 1.0, -1.0, 1.0))
    # plot_colored_oscillator(x.T, y.T)  # currently shape issues
    # plot_colored_oscillator(x[0, :], y[0, :])  # Plot first oscillator

    plt.gcf().set_facecolor('w')
    plt.tight_layout()
    plt.show()
    print("finished")

    # # Create time array for parameter plotting
    # t_params = np.linspace(0, 50, 500)
    # omegas = [omega_t(t) for t in t_params]
    # Ks = [K_t(t) for t in t_params]
    # lams = [lam_t(t) for t in t_params]

    # # Plot parameters over time
    # plt.figure(figsize=(12, 8))

    # plt.subplot(3, 1, 1)
    # plt.plot(t_params, omegas)
    # plt.ylabel('Frequency (rad/s)')
    # plt.title('Time-Dependent Parameters')

    # plt.subplot(3, 1, 2)
    # plt.plot(t_params, Ks)
    # plt.ylabel('Coupling Strength')

    # plt.subplot(3, 1, 3)
    # plt.plot(t_params, lams)
    # plt.ylabel('Bifurcation Parameter')
    # plt.xlabel('Time (s)')

    # plt.tight_layout()
    # plt.show()

    # Plot oscillator trajectories with color coding
    # plt.figure(figsize=(10, 6))
    # for i in range(N):
    #     plt.plot(sol.y[i, :], sol.y[N+i, :], alpha=0.7, label=f'Osc {i+1}')

    # plt.xlabel('x(t)')
    # plt.ylabel('y(t)')
    # plt.title('Kuramoto-Hopf Oscillator Network Dynamics')
    # plt.grid(True, alpha=0.3)
    # plt.legend()
    # plt.show()


def precision_t(t, N):
    """
    Returns array of precision values over time
    t: current time
    N: number of oscillators
    Returns: array of shape (N,)
    """
    # Initialize with baseline precision
    base_prec = 1.1
    prec = base_prec * np.ones(N)

    # Example: Gradual precision loss over time
    if t < 10:
        prec = base_prec * np.ones(N)
    elif t < 20:
        # Gradual precision loss
        loss_factor = 1 - 0.5 * (t - 10) / 10
        prec = base_prec * np.maximum(loss_factor, 0.5) * np.ones(N)
    elif t < 30:
        # Low precision period
        prec = 0.3 * np.ones(N)
    else:
        # Recovery period
        recovery_factor = 0.3 + 0.7 * (t - 30) / 20
        prec = base_prec * np.minimum(recovery_factor, 1.0) * np.ones(N)

    return prec


def plot_colored_oscillator(x, y):
    from matplotlib.collections import LineCollection
    from matplotlib.colors import ListedColormap, Normalize

    # Create line segments - need to reshape properly
    n_points = len(x)
    segments = np.zeros((n_points - 1, 2, 2))
    segments[:, 0, :] = np.column_stack([x[:-1], y[:-1]])  # start points
    segments[:, 1, :] = np.column_stack([x[1:], y[1:]])    # end points

    # LineCollection expects a list of segments, not a single array
    lc = LineCollection([segments], cmap='viridis',
                        norm=Normalize(0, n_points-1))

    # Use time/index for color mapping to show progression
    lc.set_array(np.arange(n_points - 1))

    plt.gca().add_collection(lc)

    # Add colorbar to show progression
    cbar = plt.colorbar(lc, label='Time Progression')

    # Set limits
    plt.xlim(min(x), max(x))
    plt.ylim(min(y), max(y))
    plt.xlabel('x(t)')
    plt.ylabel('y(t)')
    plt.title('Kuramoto Oscillator Trajectory')
    plt.grid(True, alpha=0.3)
    plt.gca().set_aspect('equal')

    # Add arrow to show direction
    # mid_idx = n_points // 4
    # # plt.annotate('', xy=(x[mid_idx+1], y[mid_idx+1]),
    # #              xytext=(x[mid_idx], y[mid_idx]),
    # #              arrowprops=dict(arrowstyle='->', color='red', lw=2))

    plt.show()

# Time-dependent frequency (alpha frequency ~8-12 Hz)


def omega_t(t):
    base_freq = 2 * np.pi * 10  # 10 Hz in rad/s
    # Simulate frequency changes during cognitive tasks
    task_modulation = 0.2 * np.sin(2 * np.pi * 0.1 * t)  # Slow modulation
    return base_freq * (1 + task_modulation)

# Time-dependent coupling (synchronization strength)


def K_t(t):
    base_coupling = 1.0
    # Stronger coupling during rest, weaker during task
    task_coupling = 0.5 * (1 + np.tanh(2 * np.sin(2 * np.pi * 0.05 * t)))
    return base_coupling * task_coupling

# Time-dependent bifurcation parameter (amplitude control)


def lam_t(t):
    # base_lam = 0.2
    base_lam = 1.0
    # I want it to be higher during resting state and lower during concentration on processing incoming stimulus
    amplitude_modulation = (
        1 + np.tanh(2 * np.sin(2 * np.pi * 0.03 * t))) / 0.3
    return base_lam * amplitude_modulation


hopf_oscillator(amp_scaling=1, num_oscillators=1, frequency_multiplier=1)

# hopf_oscillator(amp_scaling=1.1, num_oscillators=1, frequency_multiplier=1)

# hopf_oscillator(amp_scaling=2, num_oscillators=1, frequency_multiplier=1)
