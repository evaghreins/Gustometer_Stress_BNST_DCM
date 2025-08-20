%% Parametric Empirical Bayes (PEB) 

% This script reproduces the BNST effective connectivity results
% reported in the Guerrero-Hreins et al. manuscript (Figure 3a, Supplementary Table 3).

% -----------------------------------------------------------------------
% Please ensure that your SPM12 folder (r7771) is listed in your MATLAB set
% path. These results were obtained using Matlab R2023a. Values may
% slightly differ from the manuscript depending on OS and Matlab version.
% -----------------------------------------------------------------------

% This section runs a PEB model quantifying the between-subject commonality
% in connectivity parameters across the sample. The design matrix included
% an intercept term (single column of ones) denoting the overall mean
% connectivity.

clear
close all

% Load GCM and design matrix
load('../data/GCM_Stress_cue.mat');
load('../M/M_Cue/M_delta_stress.mat'); 

X = dm.X;
K = width(X);
X(:,2:K)=X(:,2:K)-mean(X(:,2:K));
X_labels = dm.labels;

M = struct();
M.Q = 'fields';
M.X = X;
M.Xnames = X_labels;

% Hierarchical PEB model estimation (select DCM parameters to take to 2nd level)
[PEB, RCM] = spm_dcm_peb(DCM, M, {'B'});
save('./PEB_B_HS_Cue_deltastress.mat', 'PEB', 'RCM');

% Hierarchical PEB model comparison (automatic search over reduced PEB models)
BMA = spm_dcm_peb_bmc(PEB);
save('./BMA_B_HS_Cue_deltastress.mat', 'BMA'); % output used to inform replication, validation, and visualisation

% Review BMA results
% -----------------------------------------------------------------------
% Second-level effect: Mean
%   Threshold: Free energy, Very Strong evidence (Pp>.99)
%   Display as matrix: B-matrix (modulatory connectivity; Input Stress_Cue)
% -----------------------------------------------------------------------
spm_dcm_peb_review(BMA, DCM);

%% Leave-one-out cross validation of BNST-to-OFC inhibition and delta stress relationship 
[qE ,qC ,Q] = spm_dcm_loo (DCM ,dm, {'B(3,1,2)'} ); %% 3 = OFC, 4 = BNST, 2 = Stress_Cue

