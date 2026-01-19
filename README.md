# README

This repository includes de-identified neuroimaging, physiological and behavioural data and scripts used in the effective connectivity analyses conducted for the Guerrero-Hreins et al. stress and BNST dynamic causal modelling (DCM) study. The data and code provided here support the main results reported in the associated manuscript.

This README provides a folder-by-folder and file-level description of the repository contents and intended usage.

---

## Repository Structure

```
Gustometer_Stress_BNST_DCM/
├── BNST_mask/                 # BNST region mask
├── M/                         # PEB design (M) matrices
├── analyses/                  # Group-level PEB analyses scripts
├── data/                      # De-identified GCMs and behavioural/demographic data
├── hrv/                       # Heart rate variability analyses
├── in_silico_validation/      # DCM simulation and validation code
├── log_files/                 # Behavioural task log files
├── scr/                       # Skin conductance response scripts and data
├── supp_analyses/             # Supplementary DCM analyses
└── README.md                  # Project documentation
```

---

## BNST_mask/

Contains the binary and probabilistic mask defining the bed nucleus of the stria terminalis (BNST) used for ROI extraction and DCM specification. This mask is referenced by analyses scripts during time-series extraction and model specification.

- BNST_overlap_mask.nii

---

## analyses/

Contains MATLAB scripts used for group-level Parametric Empirical Bayes (PEB) analyses. Separate PEB analyses were conducted for each run, task and stimulus combination:

- Run: high-stress (HS), low-stress (LS)
- Task: Cue, Taste
- Stimulus: Water (W), Chocolate Milk (M)

Each script loads the appropriate group-level DCM (GCM.mat) file from `data/` and applies the corresponding M-matrix from `M/`.

### Scripts

- Run_PEB_HS_Cue_LOOCV_deltastress.m  
  This script also includes leave-one-out cross validation (LOOCV) of the relationship between BNST-to-OFC inhibition and delta stress.
- Run_PEB_HS_MCue.m
- Run_PEB_HS_MTaste.m
- Run_PEB_HS_Taste.m
- Run_PEB_HS_Wcue.m
- Run_PEB_HS_Wtaste.m
- Run_PEB_LS_Cue.m
- Run_PEB_LS_Mcue.m
- Run_PEB_LS_Mtaste.m
- Run_PEB_LS_Taste.m

---

## M/

Contains PEB design (M) matrices used across group-level analyses.

### M_Cue/

- M_mat  
  Design matrix used for all cue-related PEB analyses.
- M_delta_stress.mat  
  Design matrix used for the Cue LOOCV delta stress PEB analysis.

### M_Taste/

- M_mat  
  Design matrix used for all taste-related PEB analyses.

---

## data/

Contains de-identified processed data products used as inputs for the PEB analyses. No raw neuroimaging data are included.

### GCM (.mat) files

- Used as direct inputs for the corresponding PEB scripts in `analyses/`
- File naming conventions:
  - LS – low stress, HS – high stress
  - Wcue – water cue, Mcue – chocolate milk cue
  - Wtaste – water taste, Mtaste – chocolate milk taste

### Additional files

- sex_ID.mat  
  Table mapping:
  - ID – participant identifier
  - gcm_idx – subject index/order within corresponding GCM_*.mat files
  - sex – recorded as M/F

- Demographic_Behaviour_data.xlsx  
  Demographic and behavioural summary measures

---

## hrv/

Contains MATLAB scripts related to heart rate variability (HRV) and heart rate (HR) analyses conducted alongside the fMRI task.

- HRV_figure.m
- HRV_combined_R1.m
- HRV_vectors_all_participants.mat
- HR_analyses_R3.m
- R2_HRV_comp.m
- all_cpulse_values.mat

---

## in_silico_validation/

Contains MATLAB scripts used for in-silico validation of DCM.

- reformat_fig.m
- run_validation.m
- validate_task_model.m

---

## log_files/

Contains behavioural log files exported from the PsychoPy fMRI gustometer task. File names include subject ID and stress run.

- *_gusto_1_*_001.txt — Run 1 (Low Stress)
- *_gusto_2_*_002.txt — Run 2 (High Stress)

These logs are parsed to extract:

- Cue and Taste onset times
- Condition labels
- Stress, hunger and beverage pleasantness ratings

They serve as the primary input for condition-file generation.

---

## scr/

Contains scripts and data related to skin conductance analyses.

### review/

- EGH_discarded_files.txt
- EGH_edited_files.txt
- MG_discarded_files.txt
- MG_edited_files.txt

### sf/

- *_Stress1_sf.mat
- *_Stress2_sf.mat

### Scripts

- stress_irr.m
- stress_mp.m
- stress_test.m

---

## supp_analyses/

This folder contains all MATLAB scripts used to retrofit, re-invert, and analyse dynamic causal models (DCMs) for the gustometer fMRI task. These scripts accompany the supplementary analyses reported with the manuscript. See internal README.md for more information.

---

## Dependencies

- MATLAB (R2020b or later recommended)
- SPM12 (DCM12+)

---

## Acknowledgements

If you use this repository, please cite the associated manuscript by Guerrero-Hreins et al. (details to be added upon publication).
