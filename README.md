# Alpha wave modelling and simulation 🧠📈

_Testing hypotheses about modulation of brain waves under stimulus anticipation_

A computational neuroscience project for my master's thesis, focusing on studying how modulation of brain waves occurs under anticipation of incoming stimulus. Comparison is between different cases of temporal predictability.

---

## Table of Contents

- [Overview](#-project-overview)
- [Technologies Used](#-technologies-used)
- [Topics Explored](#-topics-explored)
- [Preliminary Results](#preliminary-graph-results)
- [Getting Started](#-getting-started)
- [Architecture](#-architecture)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## 🎯 Project Overview

A computational neuroscience project for my master's thesis, focusing on studying how modulation of brain waves occurs under anticipation of incoming stimulus. Comparison is between different cases of temporal predictability, currently focusing on the auditory domain [^1].

[^1]:
    Morillon, B., Schroeder, C. E., Wyart, V., & Arnal, L. H. (2016). [Temporal Prediction
    in lieu of Periodic Stimulation. The Journal of neuroscience : the official journal of the Society for Neuroscience, 36(8), 2342–2347.](https://doi.org/10.1523/JNEUROSCI.0836-15.2016).

### Abstract

Alpha wave oscillations (8–12 Hz) have long been associated with alertness and attentional mechanisms.
However, their functional role and potential differences between sensory modalities remain debated [^2], as
does their causal effect on perception and behavior. Aiming to better understand these effects, we explore
how stimulus anticipation modulates alpha amplitude and phase, with the future goal of developing models
for BCI applications reliant on accurate attention estimation and real-time decoding of these modulations.

[^2]: Bonnefond M, Jensen O. The role of alpha oscillations in resisting distraction. Trends Cogn. Sci.. 2025;29(4):368–379.

### State of field

It is well established, at least in vision, that low alpha power is associated with facilitated processing of
the corresponding sensory feature, while, conversely, high power is associated with its inhibition. Further-
more, the phase of alpha oscillations at stimulus presentation time has been shown to impact behavioral
performance. Finally, alpha oscillations are asymmetric: e.g., their power modulations affect peaks but not
troughs. An idea is that alpha represents pulses of inhibition, thus directly influencing the processing of in-
coming stimuli. For example, manipulating the predictability of stimuli and the resulting anticipation induces
a modulation of phase or amplitude that affects our perceptual abilities [^3]. A remaining gap is understanding
and validating the specific role of distinct modulation of phase and amplitude, and the resulting effect on per-
ception of incoming stimuli and behavior, particularly in cases of limited attentional resources and taking into
account contextual information (e.g., temporal or spatial predictability)

[^3]: Samaha J, Bauer P, Cimaroli S, Postle BR. Top-down control of the phase of alpha-band oscillations as a mechanism for temporal prediction. Proc. Natl. Acad. Sci. U. S. A.. 2015;112(27):8439–8444.

#### Methodology

We propose a phenomenological generative process of alpha rhythms across trials and their impact on
perception. To do this, we combine a probabilistic (learning) model of perception[^4], where beliefs and uncer-
tainty about future stimuli are encoded in the form of a best guess about the timing of the incoming stimulus,i
as well as the a precision level of that belief. These estimates are updated trial by trial, and modulate the am-
plitude and phase of oscillations, which influences the behavioral output in terms of both choice and reaction
time. Current work consists of implementing this model and simulating its predictions in discrimination or
perceptual detection tasks (auditory or visual) that manipulate stimulus predictability.

[^4]: Lecaignard F, Bertrand O, Caclin A, Mattout J. Neurocomputational underpinnings of expected surprise. J. Neurosci.. 2022;42(3):474–486. -->

### Future work

- Improving the model, and building upon it to extend other paradigms (such as in the visual domain), or explore other modalities of expectation (e.g spatial).

- Collecting real experimental EEG data and comparing with model expectation and hypothesis.

---

## 🛠️ Technologies Used

### Code

- **Matlab** - Multi-paradigm programming language and numeric computing environment
- **Python** - Programming language
- **VBA toolbox** [^5] - Scientific toolbox for variational bayesian analysis
- **Statistics and ML toolbox** - Scientific toolbox for variational bayesian analysis

### 📖 Topics explored

- **Bayesian learning**
- **Variational Bayesian Analysis**
- **Signal Detection Theory**
- **Neural mass models and oscillators**
- **Drift Diffusion Models**
- **Effect of Brain states on Perception**

---

### Preliminary Graph Results

![Changing Posterior Precision](<Screenshot 2026-04-20 154535.png>)
_Changing precision of beliefs throughout trials under predictable and unpredictable trial blocks_

![alt text](<Screenshot 2026-04-14 143111.png>)
_Difference in delta phase error between conditions_

![alt text](<Screenshot 2026-04-20 170358.png>)
_Difference in Reaction Time between conditions_

---

## 🚀 Getting Started

### Prerequisites

- Matlab
- VBA toolbox
- Statistics and Machine learning toolbox

[^5]: J. Daunizeau, V. Adam, L. Rigoux (2014), VBA: a probabilistic treatment of nonlinear models for neurobiological and behavioural data. PLoS Comp Biol 10(1): e1003441.

### Reproduction

1. **Install prerequisites**

    Ensure you have a working installation of matlab, as well as the necessary toolboxes.

2. **Clone the repository**

    ```bash
    git clone https://github.com/Isracoder/alpha-model.git
    ```

3. **Run locally**
   Run the simul_data file, passing in all relevant arguments such as the number of subjects, the chosen learning and observation models, and the flag for listening to an example of the stimulus
    ```matlab terminal
    simul_data(3, 2, 4, 0)
    ```

Corresponding graphs will appear post-run

---

## 🏗️ Architecture

The application follows a function-based architecture, with separation of concerns, following is a description of the main directories:

- **Learning**: Each contained file is a separate function that can be used to mix and match models when learning hidden states of the participant.
- **Observation**: Each contained file is a separate function that can be used to mix and match models when mapping observations (e.g using a function to map to choice observables based on Signal Detection Theory). Subdirectories are split into choice and neural-based models, with later plans on merging the two.
- **Neural_MM**: Files here are alternative models explored, such as the Jansen-Rit neural mass model, and a kuramoto based hopf style oscillator.

---

## 📄 License

Any use of this code must be in accordance with the license, and with authorization of the CRNL and initial code contributors.

## 📞 Contact & Support

- Feedback and contribution on taking this project to the next step is welcome, don't hesitate to get in touch.

---

## 🙏 Acknowledgments

- Thank you to my supervisor in this project Jeremie Mattout, as well as those who provided me with guidance such as Elif Koksal Ersoz, Francoise Lecaignard, and Mathilde Bonnefond .

---

_Made with ❤️ for the computational neuroscience community_
