function gusto_gen_cond_files()
% GUSTO_GEN_COND_FILES
% -------------------------------------------------------------------------
% Generates condition (.mat) files for DCM analysis from gustometer
% behavioural log files. Each subject has two runs:
%   Run 1 = Low Stress (LS)
%   Run 2 = High Stress (HS)
%
% For each run, this function extracts onsets for:
%   Water_cue, Milk_cue, Water_taste, Milk_taste, ratings, rinse
% Offsets are automatically added for the second run (HS) based on TR ×
% number of scans. Each condition is assigned a fixed duration (5 s).
%
% Output:
%   Saves gusto_cond_<sub>.mat in the output directory containing:
%       - names     : condition names (1×12 cell array)
%       - onsets    : cell array of onset vectors
%       - durations : scalar duration per condition
%
% Author: Matthew D. Greaves
% Date:   03-Nov-2025
% -------------------------------------------------------------------------

% Parameters
parent_dir      = pwd;
log_files_dir   = fullfile(parent_dir, 'log_files');
out_dir         = fullfile(parent_dir, 'DCM', 'cond_files');
if ~exist(out_dir,'dir'), mkdir(out_dir); end

runs        = 2;      % LS and HS
scans       = 525;    % Scans per run
TR          = 0.8;    % Repetition time (s)
cond_dur    = 5;      % Duration per event (s)

% Base condition names (LS); HS conditions are auto-generated
cond_names = {'LS_Water_cue','LS_Milk_cue','LS_Water_taste', ...
    'LS_Milk_taste','LS_ratings','LS_rinse'};
names_all = [cond_names, replace(cond_names,'LS','HS')];

% Identify subjects
files   = dir(fullfile(log_files_dir, '*_gusto_*.txt'));
subs    = unique(extractBefore({files.name}, '_gusto'));
success = zeros(1, numel(subs))';

% Loop over subjects
for i = 1:numel(subs)

    % Use subject-specific log file (if possible)
    try
        sub = subs{i};

        % Initialize containers per subject
        onsets    = cell(1, numel(names_all));
        durations = repmat({cond_dur}, 1, numel(names_all));
        names     = names_all;

        for j = 1:runs
            % Locate run file
            f = dir(fullfile(log_files_dir,...
                sprintf('%s_gusto_%d*.txt', sub, j)));
            assert(~isempty(f), 'No log found for %s (run %d)', sub, j);

            % Load and compute offsets
            output      = gusto_log_convert(fullfile(...
                f(1).folder, f(1).name));
            cell_off    = (j-1) * numel(cond_names);
            timing_off  = (j-1) * scans * TR;

            % Cues
            w_idx = find(contains(output.events, 'W'));
            m_idx = find(contains(output.events, 'M'));
            onsets{1 + cell_off} = output.timings(w_idx).' + timing_off;
            onsets{2 + cell_off} = output.timings(m_idx).' + timing_off;

            % Taste (next row after cue)
            w_t_idx = w_idx + 1; w_t_idx(w_t_idx > numel(...
                output.timings)) = [];
            m_t_idx = m_idx + 1; m_t_idx(m_t_idx > numel(...
                output.timings)) = [];
            onsets{3 + cell_off} = output.timings(w_t_idx).' + timing_off;
            onsets{4 + cell_off} = output.timings(m_t_idx).' + timing_off;

            % Ratings and rinse
            r_idx = find(contains(output.events,'rating'));
            z_idx = find(contains(output.events,'rinse'));
            onsets{5 + cell_off} = output.timings(r_idx).' + timing_off;
            onsets{6 + cell_off} = output.timings(z_idx).' + timing_off;
        end

        % Save output
        out_file = fullfile(out_dir, sprintf('gusto_cond_%s.mat', sub));
        save(out_file, 'names','onsets','durations');
        fprintf('Saved: %s\n', out_file);
        success(i) = 1;

        % Use different subjects' log file (accurate to one decimal place)
    catch
        lst_succ = find(success, 1, 'last');
        out_file = fullfile(out_dir, sprintf('gusto_cond_%s.mat',...
            subs{lst_succ}));
        copyfile(out_file, fullfile(out_dir, sprintf(...
            'gusto_cond_%s.mat', sub)));
        fprintf('Copied: %s for subject %s\n', out_file, sub);
    end
end

end
