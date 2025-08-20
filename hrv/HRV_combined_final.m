% Load HRV data
load('HRV_vectors_all_participants.mat');

% Excluded participants (poor pulse trace)
excluded = {'Sub107', 'Sub133', 'Sub139', 'Sub147', 'Sub151'};

% Scanning Parameters
TR = 0.8;
n_timepoints = floor(20 / TR); % First 20 seconds = 25 samples
bin_proportion = 0.035; % ~3.5% of full time series

% Get valid participants
participants = setdiff(fieldnames(HRV_vectors), excluded);

% Storage
LS_means_early = [];
HS_means_early = [];
data = {};

for i = 1:length(participants)
    p = participants{i};
    entry = HRV_vectors.(p);

    if ~isfield(entry, 'LS') || ~isfield(entry, 'HS')
        continue;
    end

    ls = entry.LS(:);
    hs = entry.HS(:);

    if length(ls) < n_timepoints || length(hs) < n_timepoints
        continue;
    end

    % First 20 sec t-test data
    LS_means_early(end+1) = mean(ls(1:n_timepoints));
    HS_means_early(end+1) = mean(hs(1:n_timepoints));

    % Windowing for ANOVA
    n = length(ls);
    seg = floor(n * bin_proportion);
    if seg < 10
        continue;
    end

    % Define windows
    mid_start = floor(n/2 - seg/2 + 1);
    
    windows = {
        mean(ls(1:seg)),         'LS_early';
        mean(ls(mid_start:mid_start+seg-1)), 'LS_middle';
        mean(ls(end-seg+1:end)), 'LS_late';
        mean(hs(1:seg)),         'HS_early';
        mean(hs(mid_start:mid_start+seg-1)), 'HS_middle';
        mean(hs(end-seg+1:end)), 'HS_late';
    };

    for j = 1:size(windows,1)
        data(end+1,:) = {p, windows{j,2}, windows{j,1}};
    end
end

% ----- Output: T-test for first 20 seconds -----
[~, p, ~, stats] = ttest(LS_means_early, HS_means_early);
fprintf('--- First 20 Seconds: Paired t-test (LS vs HS) ---\n');
fprintf('Mean HRV (LS): %.4e\n', mean(LS_means_early));
fprintf('Mean HRV (HS): %.4e\n', mean(HS_means_early));
fprintf('t(%d) = %.2f, p = %.4f\n', stats.df, stats.tstat, p);

% ----- Repeated-Measures ANOVA -----
T = cell2table(data, 'VariableNames', {'Participant', 'Label', 'HR_Mean'});
T.Participant = categorical(T.Participant);
T.Label = categorical(T.Label);
T_wide = unstack(T, 'HR_Mean', 'Label');
T_wide = rmmissing(T_wide);

within = table(...
    categorical([repmat({'LS'},3,1); repmat({'HS'},3,1)]), ...
    categorical(repmat({'early'; 'middle'; 'late'}, 2, 1)), ...
    'VariableNames', {'Condition','Time'});

rm = fitrm(T_wide, ...
    'LS_early,LS_middle,LS_late,HS_early,HS_middle,HS_late ~ 1', ...
    'WithinDesign', within);
ranovatbl = ranova(rm, 'WithinModel', 'Condition*Time');

fprintf('\n--- Repeated-Measures ANOVA ---\n');
disp(ranovatbl);

% ----- Post-hoc T-Tests -----
diff_em_ls = T_wide.LS_middle - T_wide.LS_early;
diff_em_hs = T_wide.HS_middle - T_wide.HS_early;
[~, p_em, ~, stats_em] = ttest(diff_em_ls, diff_em_hs);

diff_el_ls = T_wide.LS_late - T_wide.LS_early;
diff_el_hs = T_wide.HS_late - T_wide.HS_early;
[~, p_el, ~, stats_el] = ttest(diff_el_ls, diff_el_hs);

fprintf('\n--- Paired t-test: Early → Middle ---\n');
fprintf('LS mean change: %.4f | HS mean change: %.4f\n', mean(diff_em_ls), mean(diff_em_hs));
fprintf('t(%d) = %.2f, p = %.4f\n', stats_em.df, stats_em.tstat, p_em);

fprintf('\n--- Paired t-test: Early → Late ---\n');
fprintf('LS mean change: %.4f | HS mean change: %.4f\n', mean(diff_el_ls), mean(diff_el_hs));
fprintf('t(%d) = %.2f, p = %.4f\n', stats_el.df, stats_el.tstat, p_el);
