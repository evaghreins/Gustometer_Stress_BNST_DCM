function gusto_results(save_flag)
% GUSTO_RESULTS
% -------------------------------------------------------------------------
% Purpose:
%   Extract and display significant group-level modulatory (B-matrix)
%   effects from the PEB/BMA analyses of the retrofitted cue and taste
%   DCMs. This is intended for supplementary materials or reporting
%   purposes.
%
% What it does:
%   • Loads example DCM to recover region names and modulatory structure.
%   • Loops over both models: 'cue' and 'taste'.
%   • Loads Bayesian Model Averaging (BMA) results for each model.
%   • Extracts posterior means, variances, and probabilities (pP).
%   • Applies a posterior probability threshold (default = 0.75).
%   • Prints all significant directed connections for each modulator.
%   • Optionally saves all results into a .mat file ('gusto_supp.mat').
%
% Key assumptions:
%   • PEB results are stored in <pwd>/PEB/<model>/BMA_<model>.mat.
%   • The DCMs contain consistent B-matrix masks across subjects.
%   • Modulators correspond to columns in DCM.U.name 
%     (typically 'Task', 'Stress', 'Stimulus').
%   • Only thresholded, significant effects are reported.
%
% Inputs:
%   save_flag (logical) - if true, saves outputs to 'gusto_supp.mat'.
%
% Outputs (if save_flag = true):
%   models   - {'cue', 'taste'}
%   regions  - region names (same order as DCM.Y.name)
%   mods     - modulator names (e.g. 'Task','Stress','Stimulus')
%   results  - cell array of B-matrix effects per model, thr > 0.75
%
% Example:
%   gusto_results(true);  % runs extraction and saves results
%
% Author: Matthew D. Greaves
% Date:   05-Nov-2025
% -------------------------------------------------------------------------

% Paths
peb_path    = fullfile(pwd, 'PEB');
models      = {'cue', 'taste'};

% Load example DCM
dcm_files   = dir(fullfile(peb_path, '*dcm*.mat'));
load(fullfile(dcm_files(1).folder, dcm_files(1).name), 'DCM');

% Recover region names and modulation indicies
regions = extractBefore(DCM.Y.name, '_');       % Region names
n       = DCM.n;                                % Number of regions
m       = find(any(any(b)));                    % Modulators
mods    = extractBefore(DCM.U.name(m), '_');    % Modulator names
l       = numel(m);                             % Number of modulators
indx    = find(DCM.b(:,:,m(1)));                % Pattern of modulation 
                                                % (assumed to be the same)
% Threshold and store results
results     = cell(1,l);
for i = 1:numel(models)

    % Load BMA posterior
    BMA = load(fullfile(peb_path, models{i}, ['BMA_', models{i},...
        '.mat']), 'BMA').BMA;
    Ep = full(BMA.Ep); Cp = diag(full(BMA.Cp));

    % Posterior thresholding
    thr = 0.75;
    z  = abs(Ep) ./ max(eps, sqrt(Cp));
    p  = 2*(1 - 0.5*erfc(-z/sqrt(2)));
    Pp  = 1 - p;
    msk = Pp > thr;

    % Arrange in matrix format
    Ep_thr          = Ep;
    Ep_thr(~msk)    = 0;
    Ep_trh          = reshape(Ep_thr, numel(indx), l);
    Cp_rfm          = reshape(Cp, numel(indx), l);
    pP_rfm          = reshape(Pp, numel(indx), l);
    B               = zeros(n, n, l);
    for j = 1:l
        fprintf('Model: %s; Modulator: %s.\n', models{i}, lower(mods{j}));
        [r, c]      = ind2sub([n, n], indx);
        for k = 1:numel(indx)
            B(r(k), c(k), j)  = Ep_trh(k, j);

            % Print non-zero results
            if any(Ep_trh(k, j))
                fprintf(['%s   ->   %s:',...
                    '   mu = %.3f,   var = %.3f,   pP = %.3f.\n\n'],...
                    regions{c(k)}, regions{r(k)}, Ep_trh(k, j),...
                    Cp_rfm(k, j), pP_rfm(k, j));
            end
        end
        
        % Flag no effect of modulation
        if ~any(Ep_trh(:,j))
            fprintf(['No *significant* modulation by',...
                ' %s in %s model.\n\n'],...
                lower(mods{j}), models{i});
        end
    end
    results{i} = B;
end

% Save results for visualisation
if save_flag
    save('gusto_supp', "models", "regions", "mods", "results");
end

end
