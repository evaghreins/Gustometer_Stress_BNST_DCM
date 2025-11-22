# **Supplementary DCM Analyses**

This folder contains all MATLAB scripts used to **retrofit**, **re-invert**, and **analyse** dynamic causal models (DCMs) for the gustometer fMRI task.
These scripts accompany the supplementary analyses reported with the manuscript.

The full pipeline proceeds:

1. Extract behavioural timing information → condition files
2. Retrofit subject-level DCMs with new inputs
3. Run group-level PEB and BMR/BMA
4. Extract and save significant modulatory effects

---

## **File Overview**

### **1. `gusto_log_convert.m`**

Parses gustometer PsychoPy log files and returns a structured output containing:

* subject/session metadata
* pre-task ratings
* onset times and event labels for cue/taste/rinse/rating epochs
* pleasantness ratings

Used internally by `gusto_gen_cond_files`.


---

### **2. `gusto_gen_cond_files.m`**

Generates first-level **condition files** (`gusto_cond_<sub>.mat`) for all subjects.
For each subject and both runs (Low Stress, High Stress), it creates onsets for:

* Water cue
* Milk cue
* Water taste
* Milk taste
* Ratings
* Rinse

Conditions are extended for run 2 using TR × scan count.

Output: `DCM/cond_files/`.


---

### **3. `gusto_dcm_retrofit.m`**

Retrofits each subject’s original DCM by:

* reconstructing neuronal inputs (Task, Stress, Stimulus)
* rebuilding B- and C-matrix masks
* injecting modulator-specific (±0.5) regressors
* reinverting the model under the default prior

Saves: `<r2_path>/DCM/<task>/<sub>_dcm_retrofit_<task>.mat`


---

### **4. `gusto_group_peb_bmc.m`**

Runs **group-level PEB** on the B-matrices of all retrofitted cue/taste DCMs, followed by **Bayesian Model Reduction (BMR)** and **Bayesian Model Averaging (BMA)**.
Outputs:

* `PEB_<task>.mat`
* `BMA_<task>.mat`

Located in `<r2_path>/PEB/<task>/`.


---

### **5. `gusto_results.m`**

Extracts and prints **significant (>0.75 pP)** group-level modulatory effects from the BMA results for cue and taste models.
Optionally saves a summary (`gusto_supp.mat`) for visualisation.

Useful for supplementary tables and reporting.


---

## **Typical Usage**

```matlab
% 1. Generate condition files
gusto_gen_cond_files;

% 2. Retrofit and invert DCMs (loop or HPC)
gusto_dcm_retrofit(idx, GCM_path, 'cue',  r2_path);
gusto_dcm_retrofit(idx, GCM_path, 'taste', r2_path);

% 3. Group PEB + BMR/BMA
gusto_group_peb_bmc(r2_path);

% 4. Extract and (optionally) save significant results
gusto_results(true);

```

---

## **Dependencies**

* MATLAB (R2020b or later recommended)
* SPM12 (DCM12+)
* Behavioural log files: `*_gusto_1.txt`, `*_gusto_2.txt`

---
