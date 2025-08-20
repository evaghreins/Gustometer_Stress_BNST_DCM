% run_validation
% -------------------------------------------------------------------------
% This script performs a basic in silico validation of a task-based PEB
% model by comparing simulated and empirical parameter estimates using
% SPM DCM tools.

% Path to file
gcm_path        = '../data';
gcm_file_path   = {fullfile(gcm_path, 'GCM_Stress_cue.mat'),...
    fullfile(gcm_path, 'GCM_Stress_taste.mat')};

% Loop over both GCM files
for i = 1:numel(gcm_file_path)

    % Model name
    [~, name] = fileparts(gcm_file_path{i});


    % Select a subset of subjects for testing. To use all subjects set 
    % S = inf.
    S = inf;

    % Load a group of inverted DCMs (GCM) from an example dataset
    GCM = load(gcm_file_path{i}).DCM;
    if ~isinf(S)
        GCM = GCM(1:S);
    end

    % Specify the PEB model structure
    M = struct();
    M.Q = 'fields';
    M.X = ones(size(GCM));
    M.Xnames = {'Mean'};

    % Estimate the group-level PEB
    [PEB,~] = spm_dcm_peb(GCM, M, {'B'});

    % Run in silico validation:
    % Simulates new BOLD data based on estimated parameters, adds noise,
    % re-inverts the simulated DCMs, and compares results to the original 
    % PEB.
    validate_task_model(GCM, PEB, name);
end

% This component of the script generates the supplementary figure in 
% Guerrero-Hreins et al. by reformatting default output.
fig_files = cell(1,2);
for i = 1:numel(gcm_file_path)
    [~, name] = fileparts(gcm_file_path{i});
    fig_files{i} = ['results_figure_', name, '.fig'];
end
reformat_fig(fig_files);