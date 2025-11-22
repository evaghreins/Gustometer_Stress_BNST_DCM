function gusto_group_peb_bmc(r2_path)
% GUSTO_GROUP_PEB_BMC
% -------------------------------------------------------------------------
% Purpose:
%   Perform second-level (group) Parametric Empirical Bayes (PEB) followed
%   by Bayesian Model Reduction / Averaging (BMR/BMA) on subject-level DCMs
%   that were retrofitted and re-inverted for the gustometer task.
%
%   This function:
%     • Loops over {'cue','taste'} models.
%     • Loads all *_dcm_retrofit_*.mat files from <r2_path>/DCM/<task>/.
%     • Builds a simple group mean design matrix (M.X = ones(N,1)).
%     • Estimates PEB on the B-matrix parameters (effective connectivity 
%       modulation by stress and stimulus type).
%     • Runs BMR/BMA to prune nested models and recover posterior means and
%       probabilities of group effects.
%     • Saves outputs to <r2_path>/PEB/<task>/.
%
% Inputs:
%   r2_path : Path to the 'R2' directory that contains:
%                • DCM/<task>/*_dcm_retrofit_*.mat
%                • (Outputs will be placed in) PEB/<task>/
%
% Outputs (per task):
%   • PEB_<task>.mat : PEB structure (group-level model).
%   • BMA_<task>.mat : Bayesian Model Averaging results.
%
% Notes / Assumptions:
%   • Each subject-level DCM must already contain the updated inputs U
%     ('Task', 'Stress', 'Stimulus') and re-estimated parameters.
%   • Only group mean effects are modeled (no covariates; M.X = ones).
%   • B-field is the target (modulatory connectivity).
%   • Extend or modify to include covariates, A- or C-matrices if required.
%
% Author: Matthew D. Greaves
% Date:   03-Nov-2025
% -------------------------------------------------------------------------

tasks = {'cue', 'taste'};
for i = 1:numel(tasks)
    task = tasks{i};

    % Directory containing individual subject DCMs
    dcm_dir = fullfile(r2_path, 'DCM', task);
    files   = dir(fullfile(dcm_dir, '*_dcm_retrofit_*.mat'));

    % Load all DCMs into a cell array (GCM{:})
    GCM = cellfun(@(f) load(fullfile(dcm_dir,f),'DCM'), ...
        {files.name}, 'UniformOutput', false);
    GCM = cellfun(@(s) s.DCM, GCM, 'UniformOutput', false)';

    % PEB design: group mean only
    M         = struct;
    M.Q       = 'all';
    M.maxit   = 64;

    % Invert PEB with B-matrix parameters
    fprintf('Running PEB over B for %d subjects (%s)...\n',...
        numel(GCM), task);
    [PEB, ~] = spm_dcm_peb(GCM, M, 'B');

    % Utilise BMR/BMA to summarise across plausible models
    fprintf('Running BMR/BMA...\n');
    [BMA, ~] = spm_dcm_peb_bmc(PEB);

    % Save outputs
    out_dir = fullfile(r2_path, 'PEB', task);
    if ~exist(out_dir,'dir'), mkdir(out_dir); end

    save(fullfile(out_dir, ['PEB_' task '.mat']), 'PEB', '-v7.3');
    save(fullfile(out_dir, ['BMA_' task '.mat']), 'BMA', '-v7.3');
end
