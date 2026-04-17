"""
HGF Oddball Paradigm Simulation
================================
Translates the VBA f_Audio_H1 / g_Audio_Resp model into pyhgf.

Single shared parameter set for both conditions — ISI statistics
alone drive the divergence in belief trajectories.

Structure:
  generate_input()   : Python port of generate_input.m (paradigm 1)
  HGF_PARAMS         : One shared parameter dict for both conditions
  build_hgf()        : 3-level continuous HGF via pyhgf
  g_response()       : Python port of g_Audio_Resp.m
  run_simulation()   : Full pipeline + overlaid comparison plots
"""

import os
import warnings

import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D
from pyhgf.model import Network

warnings.filterwarnings("ignore")


# ═══════════════════════════════════════════════════════════════
# 0.  SHARED PARAMETERS  — one set for both conditions
# ═══════════════════════════════════════════════════════════════

HGF_PARAMS = dict(
    # Tonic volatility at each level (log scale).
    # More negative = slower belief updating at that level.
    omega_1=-4.0,   # ISI-mean level: moderate tracking speed
    omega_2=-4.0,   # log-precision level (dynamic pX): same timescale
    omega_3=-6.0,   # volatility-of-pX: slow — changes across blocks, not trials

    # Volatility coupling strengths (standard full coupling)
    kappa_1=1.0,    # x2 -> x1 volatility coupling
    kappa_2=1.0,    # x3 -> x2 volatility coupling

    # Prior means
    mu_1_0=450.0,  # neutral ISI start — middle of ISIm range [255-770] ms
    mu_2_0=1.0,    # neutral log-precision start
    mu_3_0=1.0,    # neutral volatility-of-pX start

    # Prior precisions — start uncertain, let data inform
    pi_1_0=1e-4,   # low precision on ISI mean (wide prior)
    pi_2_0=1.0,
    pi_3_0=1.0,
)

# Response model parameters (shared, natural scale = exp(P) in MATLAB)
RESP_PARAMS = dict(
    A0=2.0,    # baseline alpha amplitude
    f=10.0,   # alpha frequency (Hz)
    sig=0.05,   # DDM diffusion noise
    gam=1.0,    # DDM decision threshold
    t0=0.15,   # non-decision time (s)
    PhiOpt=0.0,    # optimal phase (fixed at 0)
    dt=1e-2,   # DDM time step (s)
    N_mc=200,    # Monte-Carlo draws per go-trial (increase for final results)
)


# ═══════════════════════════════════════════════════════════════
# 1.  INPUT GENERATION  (port of generate_input.m, paradigm 1)
# ═══════════════════════════════════════════════════════════════

ISIm = np.array([255, 290, 345, 445, 770])  # ms
TRIALS_PER_BLOCK = 50
NUM_BLOCKS = 4
MIN_GAP = 3
DEVIANT_PERCENTAGE = 0.20


def gen_pattern(n: int, n1: int, min_gap: int, rng) -> np.ndarray:
    """Binary pattern: n1 ones in n slots with min_gap zeros between ones."""
    for _ in range(10_000):
        pattern = np.zeros(n, dtype=int)
        pattern[rng.choice(n, n1, replace=False)] = 1
        diffs = np.diff(np.where(pattern)[0])
        if (len(diffs) == 0 or np.all(diffs > min_gap)) and pattern[-1] == 0:
            return pattern
    # fallback: evenly spaced
    pattern = np.zeros(n, dtype=int)
    for i in range(n1):
        pattern[min(i * (n // n1), n - 1)] = 1
    return pattern


def generate_input(t_predictable: bool, rng) -> np.ndarray:
    """
    Returns U of shape (3, n_trials):
      row 0 : go/no-go indicator (1 = go)
      row 1 : std(0) / dev(1)   (meaningful on go-trials only)
      row 2 : ISI in ms

    Predictable   : constant ISI per sub-block (one ISI value per 50-trial block)
    Unpredictable : ISI drawn randomly from ISIm each trial;
                    pre/post-target ISI equalised as in original MATLAB code
    """
    U = np.empty((3, 0), dtype=float)

    for _block in range(NUM_BLOCKS):
        for isi_val in ISIm:
            n_targets = round(TRIALS_PER_BLOCK * DEVIANT_PERCENTAGE)
            pattern = gen_pattern(TRIALS_PER_BLOCK, n_targets, MIN_GAP, rng)
            target_vals = rng.integers(0, 2, size=n_targets)
            Ua = np.zeros(TRIALS_PER_BLOCK, dtype=float)
            Ua[pattern == 1] = target_vals

            if t_predictable:
                ISI_vals = np.full(TRIALS_PER_BLOCK, float(isi_val))
            else:
                ISI_vals = ISIm[rng.integers(
                    0, len(ISIm), TRIALS_PER_BLOCK)].astype(float)
                target_pos = np.where(pattern == 1)[0]
                for p in target_pos:
                    if p == 0 or p == TRIALS_PER_BLOCK - 1:
                        continue
                    common = float(ISIm[rng.integers(0, len(ISIm))])
                    ISI_vals[p] = common
                    ISI_vals[p + 1] = common

            U = np.hstack(
                [U, np.vstack([pattern.astype(float), Ua, ISI_vals])])

    return U


# ═══════════════════════════════════════════════════════════════
# 2.  3-LEVEL CONTINUOUS HGF
# ═══════════════════════════════════════════════════════════════

def build_hgf(p: dict) -> Network:
    """
    Hierarchy (bottom to top):

      u   observed ISI (ms) - one value per trial
      x1  ISI belief mean + precision   <->  VBA fx(1), prec
      x2  dynamic log-precision (pX)    <->  VBA theta_params(2), now evolving
      x3  volatility of pX              <->  new: captures env. changeability

    x2 is a *volatility* parent of x1 (controls how uncertain x1's precision is).
    x3 is a *volatility* parent of x2 (controls how quickly pX itself can change).

    Same p dict used for BOTH conditions.
    The ISI sequence fed via input_data() is the only thing that differs.
    """
    hgf = (
        Network()
        # x1 - ISI belief (level 1)
        .add_nodes(
            kind="continuous-state",
            n_nodes=1,
            node_parameters={
                "mean":             p["mu_1_0"],
                "precision":        p["pi_1_0"],
                "tonic_volatility": p["omega_1"],
            },
        )
        # x2 - dynamic pX (level 2), volatility parent of x1
        .add_nodes(
            kind="continuous-state",
            n_nodes=1,
            node_parameters={
                "mean":             p["mu_2_0"],
                "precision":        p["pi_2_0"],
                "tonic_volatility": p["omega_2"],
            },
            volatility_children=0,
            volatility_coupling_children=p["kappa_1"],
        )
        # x3 - volatility of pX (level 3), volatility parent of x2
        .add_nodes(
            kind="continuous-state",
            n_nodes=1,
            node_parameters={
                "mean":             p["mu_3_0"],
                "precision":        p["pi_3_0"],
                "tonic_volatility": p["omega_3"],
            },
            volatility_children=1,
            volatility_coupling_children=p["kappa_2"],
        )
    )
    return hgf


def extract_trajectories(hgf: Network) -> dict:
    """Return posterior means and precisions for all 3 levels."""
    t = hgf.node_trajectories
    return {
        "mu1": np.array(t[0]["mean"]),
        "pi1": np.array(t[0]["precision"]),
        "mu2": np.array(t[1]["mean"]),
        "pi2": np.array(t[1]["precision"]),
        "mu3": np.array(t[2]["mean"]),
        "pi3": np.array(t[2]["precision"]),
    }


# ═══════════════════════════════════════════════════════════════
# 3.  RESPONSE MODEL  (port of g_Audio_Resp.m)
# ═══════════════════════════════════════════════════════════════

def g_response(traj: dict, U: np.ndarray, p: dict, rng) -> dict:
    """
    Given HGF trajectories and trial inputs, compute:
      - alpha amplitude  (A0 / entropy)
      - phase sensitivity  (driven by ISI prediction error)
      - choice + RT  (drift-diffusion, go-trials only)

    Phase simplification (PhiOpt = 0):
      phase_term = sin(2*pi*f*(ISI - mu1) / 1000)
    This is a pure function of the level-1 prediction error on ISI timing.
    """
    mu1 = traj["mu1"]
    pi1 = traj["pi1"]

    n = U.shape[1]
    Uv = U[0].astype(bool)
    Ua = U[1]
    isi = U[2]

    # cumulative elapsed time - mirrors x(6) in VBA
    Tref = np.roll(np.cumsum(isi / 1000.0), 1)
    Tref[0] = 0.0

    # Gaussian entropy: S = 0.5 * log(2*pi*e / precision)
    pi_safe = np.clip(pi1, 1e-8, None)
    S = np.clip(0.5 * np.log(2 * np.pi * np.e / pi_safe), 1e-4, None)

    # Phase sensitivity - pure ISI prediction error when PhiOpt = 0
    phase_term = np.sin(2 * np.pi * p["f"] * (isi - mu1) / 1000.0)
    phase_sensitivity = 0.2 * (1.0 + phase_term)   # range [0, 0.4]

    alpha_amp = p["A0"] / S   # high precision -> low entropy -> high amplitude

    choice = np.full(n, -1.0)
    RT = np.full(n, -1.0)

    for t_idx in range(n):
        if not Uv[t_idx]:
            continue

        if Ua[t_idx] == 1:  # deviant
            nu = (p["A0"] / S[t_idx]) * (0.0 + phase_sensitivity[t_idx])
        else:                # standard
            nu = -(p["A0"] / S[t_idx]) * (0.0 + 0.2 * phase_sensitivity[t_idx])

        ch_mc = np.zeros(p["N_mc"])
        rt_mc = np.zeros(p["N_mc"])
        for i in range(p["N_mc"]):
            z, step = 0.0, 1
            while True:
                z += nu * p["dt"] + p["sig"] * \
                    np.sqrt(p["dt"]) * rng.standard_normal()
                step += 1
                if z >= p["gam"]:
                    ch_mc[i] = 0
                    rt_mc[i] = p["t0"] + step * p["dt"]
                    break
                elif z <= -p["gam"]:
                    ch_mc[i] = 1
                    rt_mc[i] = p["t0"] + step * p["dt"]
                    break
                elif step > 5000:
                    ch_mc[i] = int(rng.random() > 0.5)
                    rt_mc[i] = p["t0"] + 5000 * p["dt"]
                    break

        choice[t_idx] = float(np.mean(ch_mc == 0) > 0.5)
        RT[t_idx] = float(np.mean(rt_mc))

    return {
        "choice":            choice,
        "RT":                RT,
        "alpha_amp":         alpha_amp,
        "phase_sensitivity": phase_sensitivity,
        "entropy":           S,
        "Tref":              Tref,
    }


# ═══════════════════════════════════════════════════════════════
# 4.  SIMULATION PIPELINE
# ═══════════════════════════════════════════════════════════════

def accuracy(U: np.ndarray, resp: dict) -> float:
    go = U[0].astype(bool)
    dev = (U[1] == 1) & go
    std = (U[1] == 0) & go
    correct = np.where(dev, resp["choice"] == 0,
                       np.where(std, resp["choice"] == 1, np.nan))
    return float(np.nanmean(correct[go]))


def smooth(x: np.ndarray, w: int = 25) -> np.ndarray:
    return np.convolve(x, np.ones(w) / w, mode="same")


def run_simulation():
    rng = np.random.default_rng(42)

    # 4a. Generate inputs
    print("Generating input sequences...")
    U_p = generate_input(t_predictable=True,  rng=rng)
    U_up = generate_input(t_predictable=False, rng=rng)
    print(
        f"  Trials - predictable: {U_p.shape[1]}  unpredictable: {U_up.shape[1]}")

    # 4b. Run HGF with identical parameters, different ISI inputs
    print("\nRunning HGF (same parameters for both conditions)...")
    hgf_p = build_hgf(HGF_PARAMS)
    hgf_p.input_data(input_data=U_p[2])

    hgf_up = build_hgf(HGF_PARAMS)
    hgf_up.input_data(input_data=U_up[2])

    traj_p = extract_trajectories(hgf_p)
    traj_up = extract_trajectories(hgf_up)

    # 4c. Response model
    print("Running response model...")
    resp_p = g_response(traj_p,  U_p,  RESP_PARAMS, rng)
    resp_up = g_response(traj_up, U_up, RESP_PARAMS, rng)

    # 4d. Summary table
    acc_p = accuracy(U_p,  resp_p)
    acc_up = accuracy(U_up, resp_up)
    rt_p = np.mean(resp_p["RT"][resp_p["RT"] > 0])
    rt_up = np.mean(resp_up["RT"][resp_up["RT"] > 0])

    print("\n" + "=" * 58)
    print(f"  {'':24} {'Predictable':>14}  {'Unpredictable':>14}")
    print("=" * 58)
    rows = [
        ("Mean pi1 (L1 precision)",  np.mean(
            traj_p["pi1"]),  np.mean(traj_up["pi1"])),
        ("Mean mu2 (dynamic pX)",    np.mean(
            traj_p["mu2"]),  np.mean(traj_up["mu2"])),
        ("Mean mu3 (volatility)",    np.mean(
            traj_p["mu3"]),  np.mean(traj_up["mu3"])),
        ("Mean alpha amplitude",     np.mean(
            resp_p["alpha_amp"]), np.mean(resp_up["alpha_amp"])),
        ("Accuracy",                 acc_p,                   acc_up),
        ("Mean RT (s)",              rt_p,                    rt_up),
    ]
    for label, vp, vup in rows:
        print(f"  {label:<24} {vp:>14.4f}  {vup:>14.4f}")
    print("=" * 58)

    # 4e. Plot
    _plot(U_p, U_up, traj_p, traj_up, resp_p, resp_up)

    return dict(
        traj_p=traj_p, traj_up=traj_up,
        resp_p=resp_p, resp_up=resp_up,
        U_p=U_p, U_up=U_up,
    )


# ═══════════════════════════════════════════════════════════════
# 5.  PLOTTING  - both conditions overlaid on each panel
# ═══════════════════════════════════════════════════════════════

C_PRED = "#3B82F6"   # blue  - predictable
C_UNPRED = "#F87171"   # red   - unpredictable
C_PHASE = "#FBBF24"   # amber - phase sensitivity
BG_FIG = "#0F172A"
BG_AX = "#1E293B"
FG = "#E2E8F0"
FG_DIM = "#64748B"


def _style(ax, title: str, ylabel: str, xlabel: str = ""):
    ax.set_facecolor(BG_AX)
    ax.tick_params(colors=FG_DIM, labelsize=8)
    ax.set_title(title, color=FG, fontsize=9, pad=5, fontweight="bold")
    ax.set_ylabel(ylabel, color=FG_DIM, fontsize=8)
    if xlabel:
        ax.set_xlabel(xlabel, color=FG_DIM, fontsize=8)
    for sp in ax.spines.values():
        sp.set_edgecolor("#334155")


def _legend(ax, extra=None):
    handles = [
        Line2D([0], [0], color=C_PRED,   lw=1.5, label="Predictable"),
        Line2D([0], [0], color=C_UNPRED, lw=1.5, label="Unpredictable"),
    ]
    if extra:
        handles += extra
    ax.legend(handles=handles, fontsize=7, facecolor=BG_AX,
              labelcolor=FG, framealpha=0.8, loc="best")


def _plot(U_p, U_up, traj_p, traj_up, resp_p, resp_up):
    print("\nPlotting...")
    t_p = np.arange(U_p.shape[1])
    t_up = np.arange(U_up.shape[1])

    fig = plt.figure(figsize=(16, 18))
    fig.patch.set_facecolor(BG_FIG)
    gs = gridspec.GridSpec(
        5, 1, figure=fig,
        hspace=0.52, left=0.08, right=0.97, top=0.94, bottom=0.05
    )

    # Panel 0: ISI sequences + mu1 belief
    ax0 = fig.add_subplot(gs[0])
    ax0.plot(t_p,  U_p[2],         lw=0.5, color=C_PRED,   alpha=0.35)
    ax0.plot(t_up, U_up[2],        lw=0.5, color=C_UNPRED, alpha=0.35)
    ax0.plot(t_p,  traj_p["mu1"],  lw=1.5, color=C_PRED)
    ax0.plot(t_up, traj_up["mu1"], lw=1.5, color=C_UNPRED)
    _style(ax0, "ISI input (faded) & Level-1 posterior mean (mu1)", "ISI (ms)")
    _legend(ax0)

    # Panel 1: Level-1 precision pi1
    ax1 = fig.add_subplot(gs[1])
    ax1.plot(t_p,  traj_p["pi1"],  lw=1.5, color=C_PRED)
    ax1.plot(t_up, traj_up["pi1"], lw=1.5, color=C_UNPRED)
    _style(ax1, "Level-1 precision (pi1)  —  posterior confidence in ISI mean", "Precision")
    _legend(ax1)
    ax1.annotate("expected higher in predictable condition",
                 xy=(0.02, 0.88), xycoords="axes fraction", color=C_PRED, fontsize=7)
    ax1.annotate("expected lower in unpredictable condition",
                 xy=(0.02, 0.76), xycoords="axes fraction", color=C_UNPRED, fontsize=7)

    # Panel 2: Level-2 mean mu2 (dynamic pX)
    ax2 = fig.add_subplot(gs[2])
    ax2.plot(t_p,  traj_p["mu2"],  lw=1.5, color=C_PRED)
    ax2.plot(t_up, traj_up["mu2"], lw=1.5, color=C_UNPRED)
    _style(
        ax2, "Level-2 mean (mu2)  —  dynamic pX  [replaces fixed theta(2) in VBA]", "mu2")
    _legend(ax2)
    ax2.annotate("This is the key new quantity: pX now evolves trial-by-trial",
                 xy=(0.02, 0.06), xycoords="axes fraction",
                 color=FG_DIM, fontsize=7, style="italic")

    # Panel 3: Level-3 mean mu3 (volatility of pX)
    ax3 = fig.add_subplot(gs[3])
    ax3.plot(t_p,  traj_p["mu3"],  lw=1.5, color=C_PRED)
    ax3.plot(t_up, traj_up["mu3"], lw=1.5, color=C_UNPRED)
    _style(ax3, "Level-3 mean (mu3)  —  volatility of pX  (environmental changeability)", "mu3")
    _legend(ax3)
    ax3.annotate("expected higher in unpredictable: env. is more changeable",
                 xy=(0.02, 0.88), xycoords="axes fraction",
                 color=C_UNPRED, fontsize=7)

    # Panel 4: Alpha amplitude & phase sensitivity
    ax4 = fig.add_subplot(gs[4])
    ax4.plot(t_p,  smooth(resp_p["alpha_amp"]),          lw=1.8, color=C_PRED)
    ax4.plot(t_up, smooth(resp_up["alpha_amp"]),
             lw=1.8, color=C_UNPRED)
    ax4.plot(t_p,  smooth(resp_p["phase_sensitivity"]),  lw=1.0, color=C_PHASE,
             alpha=0.8, ls="--")
    ax4.plot(t_up, smooth(resp_up["phase_sensitivity"]), lw=1.0, color=C_PHASE,
             alpha=0.4, ls=":")
    _style(ax4,
           "Alpha amplitude (solid)  &  phase sensitivity (dashed/dotted)  —  smoothed",
           "A.U.", "Trial")
    extra = [
        Line2D([0], [0], color=C_PHASE, lw=1.2, ls="--", label="phase (pred)"),
        Line2D([0], [0], color=C_PHASE, lw=1.2, ls=":",
               alpha=0.6, label="phase (unpred)"),
    ]
    _legend(ax4, extra=extra)

    # Global title + shared parameter annotation
    fig.suptitle(
        "3-Level HGF Oddball Simulation  |  Shared Parameters — Data-Driven Divergence",
        color=FG, fontsize=12, fontweight="bold", y=0.97
    )
    param_str = (
        f"omega1={HGF_PARAMS['omega_1']}  omega2={HGF_PARAMS['omega_2']}  "
        f"omega3={HGF_PARAMS['omega_3']}  kappa1={HGF_PARAMS['kappa_1']}  "
        f"kappa2={HGF_PARAMS['kappa_2']}  mu1_0={HGF_PARAMS['mu_1_0']} ms  "
        f"pi1_0={HGF_PARAMS['pi_1_0']}"
    )
    fig.text(0.5, 0.955, param_str, ha="center", color=FG_DIM,
             fontsize=7.5, style="italic")

    out = "/output/"

    # 1. Ensure the directory exists and is writable
    os.makedirs("output", exist_ok=True)

    # 2. Specify a full, valid path
    filepath = os.path.join("output", "plot.png")

    # 3. Save the figure
    # plt.savefig(filepath)

    # # Create the directory if it does not exist
    # if not os.path.isdir(out):
    #     os.makedirs(out)

    # Generate and save the plot
    plt.plot()
    # plt.savefig(out + "hgf_oddball_simulation.png", dpi=150,
    plt.savefig(filepath, dpi=150,
                bbox_inches="tight", facecolor=BG_FIG)
    plt.close()

    print(f"  Saved to {out}")


# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    results = run_simulation()
