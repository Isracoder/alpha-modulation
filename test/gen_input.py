import numpy as np


def generate_input(isAuditory=True, T_Predictable=True, paradigmNum=1, S_Predictable=True, deviantPercentage=0.2):

    def gen_pattern(N, N1, min_gap):
        # N: total trials, N1: number of targets, min_gap: zeros between targets
        while True:
            pattern = np.zeros(N, dtype=int)
            pattern[np.random.choice(N, N1, replace=False)] = 1
            diffs = np.diff(np.where(pattern == 1)[0])
            if np.all(diffs > min_gap) and pattern[-1] == 0:
                break
        return pattern

    if paradigmNum == 1:
        # params
        Ua = np.array([0, 1])
        ISIm = np.array([255, 290, 345, 445, 770])  # default from paper
        # ISIm = np.array([255, 500, 750, 900, 1300])  # second isi params to test more surprise
        trials_per_block = 50
        num_blocks = 4
        min_gap = 3  # min non-targets between targets

        # final matrix (3 rows: target indicator, target value, ISI)
        U = np.empty((3, 0), dtype=int)

        for block in range(num_blocks):
            for isi_idx in range(len(ISIm)):
                # 1. Target positions with spacing >= min_gap
                num_targets = round(trials_per_block * deviantPercentage)
                pattern = gen_pattern(trials_per_block, num_targets, min_gap)

                # 2. Random target values (0 or 1) for each target
                target_vals = np.random.randint(0, 2, num_targets)
                Ua = np.zeros(trials_per_block, dtype=int)
                Ua[pattern == 1] = target_vals

                # 3. ISI assignment
                if T_Predictable:
                    # --- Predictable: constant ISI in this block ---
                    ISI_vals = np.full(
                        trials_per_block, ISIm[isi_idx], dtype=int)
                else:
                    # --- Unpredictable: random ISIs with pre/post target equality ---
                    ISI_vals = ISIm[np.random.randint(
                        len(ISIm), size=trials_per_block)]
                    target_pos = np.where(pattern == 1)[0]
                    for p in target_pos:
                        # Skip targets at block boundaries (cannot have both neighbours)
                        if p == 0 or p == trials_per_block - 1:
                            continue
                        # Choose a random ISI and assign to target and its neighbours
                        common_isi = ISIm[np.random.randint(len(ISIm))]
                        # ISI_vals[p-1] = common_isi  # commented as in original code
                        ISI_vals[p] = common_isi
                        ISI_vals[p + 1] = common_isi

                # Combine and append block
                addedU = np.vstack([pattern, Ua, ISI_vals])
                U = np.hstack([U, addedU])

        # Display first few trials
        print(U[:, :10])

        return U


# generate_input()
