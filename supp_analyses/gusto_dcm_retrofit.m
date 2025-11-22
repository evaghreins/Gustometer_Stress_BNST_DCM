function gusto_dcm_retrofit(array, GCM_path, task, r2_path)
% GUSTO_DCM_RETROFIT
% -------------------------------------------------------------------------
% Purpose
%   Retrofit an already-inverted fMRI DCM with new inputs (U), switches
%   (B/C), and re-invert so that *both low- and high-stress* cue/taste
%   epochs are captured explicitly and cleanly.
%
% Design (per-subject)
%   Inputs (DCM.U.u): 3 columns on the *neuronal* time grid (DCM.U.dt)
%     1) Driver: Task_{cue|taste}     (0/1) 1 any LS/HS × Milk/Water
%     2) Mod:    Stress_{cue|taste}   (±0.5) +0.5 HS, −0.5 LS, 0 else
%     3) Mod:    Stimulus_{cue|taste} (±0.5) +0.5 Milk, −0.5 Water, 0 else
%
%   Switches
%     - C: driver only (col 1) -> set for chosen target regions (here: all)
%     - B: modulators only (cols 2–3) -> mask = logical(DCM.a) by default
%
% Inputs (arguments)
%   array    : integer index into the cell array GCM.DCM (one subject)
%   GCM_path : path to a .mat containing a cell array 'DCM'
%   task     : 'cue' or 'taste'
%   r2_path  : base R2 folder (contains 'cond_files/gusto_cond_<sub>.mat')
%
% Expected cond file (gusto_cond_<sub>.mat)
%   names     : 1×12 cellstr  (LS_* and HS_* across Water/Milk × cue/taste)
%   onsets    : 1×12 cell (sec)
%   durations : 1×12 cell/scalar (sec)
%
% Outputs
%   DCM struct saved to <r2_path>/<task>/<sub>_dcm_retrofit_<task>.mat
%
% Notes & assumptions
%   - Uses the existing DCM.U.dt (neural step) and DCM.Y.dt (TR).
%   - Keeps the original DCM.M/options/priors; does NOT overwrite them.
%   - Mean centering is implicit for modulators by construction.
%   - Subject ID is parsed from VOI names (xY) after the last underscore;
%     adjust if needed.
%
% Author: Matthew D. Greaves
% Date:   03-Nov-2025
% -------------------------------------------------------------------------

% Load DCM and condition file
GCM         = load(GCM_path, 'DCM').DCM;
DCM         = GCM{array};
sub         = extractAfter(DCM.xY(end).name, '_');
cond        = load(fullfile(r2_path, 'DCM', 'cond_files', ['gusto_cond_'...
    sub, '.mat']));
result_path = fullfile(r2_path, 'DCM', task);
if ~exist(result_path,'dir'), mkdir(result_path); end

% Check for inverted model
filename = [sub, '_dcm_retrofit_' task, '.mat'];
if ~exist(fullfile(r2_path, 'DCM', task, filename), "file")

    % Build timebases
    Ty      = DCM.v;                % Number of scans
    dty     = DCM.Y.dt;             % Repetition time
    Tdur    = Ty * dty;             % Duration in seconds
    dtu     = DCM.U.dt;             % Neuronal timestep
    Tu      = round(Tdur / dtu);    % Length of inputs
    tU      = (0:Tu-1)' * dtu;      % Neuronal time axis

    % Condition labels and indicies
    tmpl    = {'LS_Water_*', 'LS_Milk_*', 'HS_Water_*', 'HS_Milk_*'};
    labels  = replace(tmpl, '*', task);
    idx     = find(contains(cond.names, labels));

    % ---------------------------------------------------------------------
    % Rebuild neuronal inputs
    % ---------------------------------------------------------------------
    x = zeros(Tu, numel(idx));
    for j = 1:numel(idx)
        on_k  = cond.onsets{idx(j)};
        dur_k = repmat(cond.durations{idx(j)}, numel(on_k), 1);

        % Mark half-open intervals
        for k = 1:numel(on_k)
            on  = on_k(k);
            off = on + dur_k(k);
            if off <= 0 || on >= Tdur
                continue;
            end
            x(:,j) = x(:,j) | (tU >= on & tU < off);
        end
    end

    % Complete rebuild
    x       = double(x);
    driver  = double(any(x,2));
    runs    = 0.5*(x(:,3) + x(:,4)) - 0.5*(x(:,1) + x(:,2));
    stim    = 0.5*(x(:,2) + x(:,4)) - 0.5*(x(:,1) + x(:,3));

    % Store inputs
    DCM.U.u    = [driver, runs, stim];
    DCM.U.name = {['Task_',task], ['Stress_',task], ['Stimulus_',task]};

    % ---------------------------------------------------------------------
    % Rebuild neuronal modulation (skip driver)
    % ---------------------------------------------------------------------
    DCM.b = zeros(DCM.n, DCM.n, size(DCM.U.u,2));
    for j = 2:size(DCM.U.u,2)
        DCM.b(:,:,j) = DCM.a;
    end

    % ---------------------------------------------------------------------
    % Rebuild driving inputs
    % ---------------------------------------------------------------------
    DCM.c = zeros(DCM.n, size(DCM.U.u,2));
    DCM.c(:, contains(DCM.U.name, 'Task')) = 1;

    % ---------------------------------------------------------------------
    % Invert DCM
    % ---------------------------------------------------------------------

    % Invert under default prior
    DCM.M   = struct;
    DCM     = spm_dcm_estimate(DCM);

    % Save output
    save(fullfile(r2_path, 'DCM', task, filename), 'DCM');
end

end

