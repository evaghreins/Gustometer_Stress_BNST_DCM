%% Paired comparison of pulse rate (BPM): LS vs HS

load('all_cpulse_values.mat')
acv = all_cpulse_values;

subs = fieldnames(acv);

LS_bpm = [];
HS_bpm = [];

for s = 1:numel(subs)
    rec = acv.(subs{s});

    % Extract pulse
    LS_peaks = rec.GUSTO_LS;
    HS_peaks = rec.GUSTO_HS;

    if isempty(LS_peaks) || isempty(HS_peaks)
        continue
    end

    % RR intervals
    LS_rr = diff(LS_peaks);
    HS_rr = diff(HS_peaks);

    % Physiological filtering
    LS_rr = LS_rr(LS_rr > 0.3 & LS_rr < 2.5);
    HS_rr = HS_rr(HS_rr > 0.3 & HS_rr < 2.5);

    if numel(LS_rr) < 10 || numel(HS_rr) < 10
        continue
    end

    % Mean BPM
    LS_bpm(end+1,1) = 60 / mean(LS_rr);
    HS_bpm(end+1,1) = 60 / mean(HS_rr);
end

% Paired t-test
[~, p, ~, stats] = ttest(LS_bpm, HS_bpm);

fprintf('Heart rate (LS vs HS): t(%d) = %.2f, p = %.3f\n', ...
        stats.df, stats.tstat, p);
