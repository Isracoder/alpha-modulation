

# Alpha wave modelling and simulation 🧠📈

_Testing hypotheses about modulation of brain waves under stimulus anticipation_

A computational neuroscience project for my master's thesis, focusing on studying how modulation of brain waves occurs under anticipation of incoming stimulus. Comparison is between different cases of temporal predictability.

---

## Table of Contents

- [Overview](#-project-overview)
- [Technologies Used](#%EF%B8%8F-technologies-used)
- [Topics Explored](#-topics-explored)
- [Preliminary Results](#preliminary-graph-results)
- [Getting Started](#-getting-started)
- [Architecture](#%EF%B8%8F-architecture)
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

### State of art 
#### What is the SOA regarding the role of alpha ?   

It is well established, at least in vision, that low alpha power is associated with facilitated processing of the corresponding sensory feature, while, conversely, high power is associated with its inhibition. Furthermore, the phase of alpha oscillations at stimulus presentation time has been shown to impact behavioral performance. Finally, alpha oscillations are asymmetric: e.g., their power modulations affect peaks but not troughs. An idea is that alpha represents pulses of inhibition, thus directly influencing the processing of incoming stimuli. For example, manipulating the predictability of stimuli and the resulting anticipation induces a modulation of phase or amplitude that affects our perceptual abilities [^3].  
A remaining gap is understanding and validating the specific role of distinct modulation of phase and amplitude, and the resulting effect on perception of incoming stimuli and behavior, particularly in cases of limited attentional resources and taking into account contextual information (e.g., temporal or spatial predictability)

[^3]: Samaha J, Bauer P, Cimaroli S, Postle BR. Top-down control of the phase of alpha-band oscillations as a mechanism for temporal prediction. Proc. Natl. Acad. Sci. U. S. A.. 2015;112(27):8439–8444.

#### Methodology

<img width="1801" height="799" alt="image" src="https://github.com/user-attachments/assets/bbfbb0b3-9b56-4ac9-9118-506d4f04c4c3" />        


We propose a phenomenological generative process of alpha rhythms across trials and their impact on
perception. To do this, we combine a probabilistic (learning) model of perception[^4], where beliefs and uncertainty about future stimuli are encoded in the form of a best guess about the timing of the incoming stimulus,as well as the a precision level of that belief. These estimates are updated trial by trial, and modulate the amplitude and phase of oscillations, which influences the behavioral output in terms of both choice and reaction time. Current work consists of implementing this model and simulating its predictions in discrimination or perceptual detection tasks (auditory or visual) that manipulate stimulus predictability.

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

#### Here we observe a qualitative reproduction of the Morillon study that we were inspired by        

<img width="945" height="435" alt="image" src="https://github.com/user-attachments/assets/c14b94fe-40b4-42bd-9df1-1237eed8b785" />

<!--
#### Here we notice Modals M1 and M3 compared
Each model induces differences in predictive precision, with M3 succeeding in showcasing a difference between the predictable and unpredictable condition

<img width="1614" height="804" alt="predictive_precision_noDiff_M1" src="https://github.com/user-attachments/assets/38706079-ba9b-4136-a7c0-d96754521144" />   

_Changing precision of beliefs throughout trials under predictable and unpredictable trial blocks, model M1_    


<img width="1614" height="793" alt="predictve_prec_diff" src="https://github.com/user-attachments/assets/fc9b7b72-804f-4fbf-b53c-43ce21accaf6" />   

_Changing precision of beliefs throughout trials under predictable and unpredictable trial blocks, model M3_

#### Effect of precision on observables

<img width="1660" height="801" alt="accuracy_diff" src="https://github.com/user-attachments/assets/b83dfdfb-0d68-4e9e-985e-7ff69efba0ce" />    

_Modulated precision from M3 induces difference in accuracy_    

 
<img width="1650" height="793" alt="accuracy_no_diff" src="https://github.com/user-attachments/assets/d5c28171-9294-476e-aea0-8fb1f4f0e069" />         

_Non-distinguishable precision from M1 leads to no significant difference in choice accuracy_   


<img width="1708" height="791" alt="reaction_time_difference_sdt" src="https://github.com/user-attachments/assets/d29a33dc-4db1-4582-aa42-e41b59d1a08a" />    

_Difference in Reaction Time between conditions under case of modulated precision_       


<img width="1581" height="774" alt="amplitude_diff" src="https://github.com/user-attachments/assets/d36f8c65-1ba4-471a-b11e-41cf42e4f9b1" />        

_Modulation of amplitude influences by modulation of predictive precision_     
--> 



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

### Parameters & Model Explainer

Flags passed to simulData are (Ns, Mt, Gt, flag, and difficulty).

- Ns is the chosen number of subjects for simulation, with each getting their own simulation, note that it must be greater than 1 to perform the statistical significance test (e.g when looking at choice accuracy).
- Flag is for hearing the auditory simulation or not
- Difficulty sets the values of the standard/deviant tones. Relevant in the case of the signal detection theory model only, and default is 440/880 Hz respectively.

#### As for the Mt and Gt parameters:

    TlDR; Possible recommended simulations are

    - simul_data(2, 4, 1, 1) --> looks at kuramoto model
    - simul_data(2, 3, 2, 1) --> gamma learning of pX + SDT
    - simul_data(2, 3, 3, 1) --> gamma learning pX + DDM
    - simul_data(2, 1, 3, 1) --> no change in pX + DDM

    To speed up DDM model can change timestep, or number of simulations within that function (currently 0.01 and 1000 respectively)

Currently to run the code you must make two choices regarding functions in order to form your model.
Formally, a [model M consists of a learning function F and an observation function G](https://mbb-team.github.io/VBA-toolbox/wiki/Structure-of-VBA's-generative-model/#evolution-and-observation-mappings), of which there are numerous examples in the code. The Mt flag in simul_data references the f function, and the Gt flag references the chosen G function

The learning functions :

- ( Mt = 0) Here the learning function is based on F audio H0 which assumes a fixed gaussian representing incoming stimulus
- ( Mt = 1) Here the learning function is based on F audio H1 which assumes a shifting gaussian, but the precision on your prior (pX) is fixed throughout simulation. (note that Mt = 2 is currently unimplemented)
- ( Mt = 3) Here the learning function assumes a shifting gaussian, and pX is also changing over time based on a gamma distribution with forgetting.
- ( Mt = 4) The same as the previous model, but with a kuramoto style update of x,y cartesian coordinate values for the oscillator, and amplitude will be derived from this kuramoto hopf oscillator as well.

The observation functions :

- ( Gt = 0) This maintains the exact initial amplitude and phase over time, passing them on with no change. Initially just added for a null comparison and now is legacy. Can use whichever Mt, this model isn't inherently part of analysis.
- ( Gt = 1) This is based on the kuramoto style augmented learning function. Output is the amplitude and phase. Requires Mt value of 4.
- ( Gt = 2) This function is based on signal detection theory for calculating the choice and RT. In addition, it uses the same method of calculation for amp/phase as function below. Can use Mt values of 1, 3, and 4.
- ( Gt = 3) Initial observation function that has entropy (modulated by predictive precision) and phase play a role in calculating the drift factor that influences the DDM used to predict choice and RT. Amplitude is represented as a sin wave (modulated by phase) that is scaled by power modulated by entropy. Can use Mt values of 1, 3, and 4.

---

## 🏗️ Architecture

The application follows a function-based architecture, with separation of concerns, following is a description of the main directories:

- **Learning**: Each contained file is a separate function that can be used to mix and match models when learning hidden states of the participant.
- **Observation**: Each contained file is a separate function that can be used to mix and match models when mapping observations (e.g using a function to map to choice observables based on Signal Detection Theory). Subdirectories are split into choice and neural-based models, with later plans on merging the two.
- **Neural_MM**: Files here are alternative models explored, such as the Jansen-Rit neural mass model, and a kuramoto based hopf style oscillator.

---

## 📄 License

Any use of this code must be in accordance with the license, and with authorization of the CRNL and initial code contributors.

## 📞 Contact

- Feedback and contribution on taking this project to the next level is welcome, don't hesitate to get in touch.

---

## 🙏 Acknowledgments

- Thank you to my supervisor in this project Jeremie Mattout, as well as those who provided me with guidance such as Elif Koksal Ersoz, Francoise Lecaignard, and Mathilde Bonnefond .

---

_Made with ❤️ for the computational neuroscience community_
