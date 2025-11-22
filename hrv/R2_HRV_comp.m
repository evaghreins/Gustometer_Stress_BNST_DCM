clear; clc;

%% Load data 
S   = load('all_cpulse_values.mat');
acv = S.all_cpulse_values;                 % 1x1 struct of participants
P    = fieldnames(acv);                    % {'P100','P101',...}

% Exclude (poor trace)
exclude = {'Sub107','Sub133','Sub139','Sub147','Sub151'};
P = setdiff(P, exclude);

%% Analysis parameters
fs_tacho      = 4;            % Hz for tachogram resampling
rr_min_s      = 0.3;          % RR lower bound
rr_max_s      = 2.5;          % RR upper bound
lf_band       = [0.04 0.15];  % Hz
hf_band       = [0.15 0.40];  % Hz
min_len_psd_s = 20;           % >=20 s to attempt PSD

metrics_names = {'pNN20','pNN50','SD1_SD2','LF_HF'}; 
%% Collect per-participant metrics
rows = cell(0, 2 + numel(metrics_names));  % {Participant, Condition, metrics...}

for i = 1:numel(P)
    pid = P{i};
    pdata = acv.(pid);                      % struct with GUSTO_LS / GUSTO_HS

    ls = double(pdata.GUSTO_LS(:));
    hs = double(pdata.GUSTO_HS(:));

    mLS = comp_metrics(ls, fs_tacho, rr_min_s, rr_max_s, lf_band, hf_band, min_len_psd_s);
    mHS = comp_metrics(hs, fs_tacho, rr_min_s, rr_max_s, lf_band, hf_band, min_len_psd_s);

    if isempty(mLS) || isempty(mHS), continue; end

    vals_ls = cellfun(@(nm) mLS.(nm), metrics_names, 'UniformOutput', false);
    rows(end+1,:) = [{pid,'LS'}, vals_ls];

    vals_hs = cellfun(@(nm) mHS.(nm), metrics_names, 'UniformOutput', false);
    rows(end+1,:) = [{pid,'HS'}, vals_hs];
end

T = cell2table(rows, 'VariableNames', ['Participant','Condition', metrics_names]);

%% Paired tests (HS vs LS) on the four metrics
stats_rows = {};
for k = 1:numel(metrics_names)
    metric = metrics_names{k};
    W = unstack(T(:,{'Participant','Condition',metric}), metric, 'Condition', 'GroupingVariables','Participant');
    if ~all(ismember({'LS','HS'}, W.Properties.VariableNames)), continue; end

    x = W.LS; y = W.HS;                          % LS vs HS
    mask = ~(isnan(x) | isnan(y));
    x = x(mask); y = y(mask);
    if numel(x) < 3, continue; end

    diffv = y - x;
    [~, p, ~, st] = ttest(x, y);                 % paired t-test
    dz   = mean(diffv) / std(diffv, 0);          % Cohen's dz
    stats_rows(end+1,1:9) = {metric, numel(x), st.tstat, st.df, p, dz, mean(x), mean(y), mean(diffv)}; %#ok<AGROW>
end

Stats = cell2table(stats_rows, 'VariableNames', ...
    {'Metric','n','t','df','p','dz','mean_LS','mean_HS','diff_mean'});
Stats = sortrows(Stats,'p');

disp('--- Paired t-tests (HS vs LS) ---');
disp(Stats);

% Display
report_metrics = {'pNN20','pNN50','LF_HF','SD1_SD2'};
for r = 1:numel(report_metrics)
    m = report_metrics{r};
    row = Stats(strcmp(Stats.Metric, m), :);
    if ~isempty(row)
        fprintf('%s: t(%d)=%.6f, p=%.6f, dz=%.6f, meanΔ=HS-LS=%.6f\n', ...
            row.Metric{1}, row.df(1), row.t(1), row.p(1), row.dz(1), row.diff_mean(1));
    end
end

% Save tables
writetable(T,     'hrv_comp_by_participant.csv');
writetable(Stats, 'hrv_comp_paired_tests.csv');

%% ---------- Local Functions (minimal) ----------
function M = comp_metrics(cpulse_secs, fs, rr_min_s, rr_max_s, lf_band, hf_band, min_len_psd_s)
    % Build RR from cumulative pulse times (seconds) with sanity bounds
    [rr, tmid] = local_ibi(cpulse_secs, rr_min_s, rr_max_s);
    if isempty(rr), M = []; return; end

    % Time-domain differences (ms) for pNN20/pNN50
    rr_ms = rr * 1000;
    diffs = diff(rr_ms);
    M.pNN20 = mean(abs(diffs) > 20) * 100;
    M.pNN50 = mean(abs(diffs) > 50) * 100;

    % Poincaré ratio SD1/SD2 (population variance convention)
    if numel(rr_ms) >= 3
        rr1 = rr_ms(1:end-1);
        rr2 = rr_ms(2:end);
        d12 = rr2 - rr1;
        sd1 = sqrt(var(d12, 1)/2);
        sd2 = sqrt(2*var(rr_ms,1) - var(d12,1)/2);
        M.SD1_SD2 = sd1 / sd2;
    else
        M.SD1_SD2 = NaN;
    end

    % LF/HF from HR tachogram Welch PSD
    hr = 60 ./ rr;
    if numel(rr) >= 4 && (tmid(end) - tmid(1)) >= min_len_psd_s
        t = tmid(:);
        t_uniform  = (t(1):1/fs:t(end))';
        hr_uniform = interp1(t, hr(:), t_uniform, 'linear', 'extrap');
        hr_uniform = detrend(hr_uniform, 'linear');
        nperseg = min(numel(hr_uniform), fs*64);
        if nperseg < 32
            M.LF_HF = NaN;
        else
            [Pxx, f] = pwelch(hr_uniform, hamming(nperseg), [], [], fs);
            LF = bandpow(f, Pxx, lf_band(1), lf_band(2));
            HF = bandpow(f, Pxx, hf_band(1), hf_band(2));
            M.LF_HF = (HF > 0) * (LF / HF);
            if HF <= 0, M.LF_HF = NaN; end
        end
    else
        M.LF_HF = NaN;
    end
end

function [rr, tmid] = local_ibi(cpulse_secs, rr_min_s, rr_max_s)
    x = sort(double(cpulse_secs(:)));
    x = x(~isnan(x));
    if numel(x) < 3
        rr = []; tmid = []; return;
    end
    rr0   = diff(x);
    tmid0 = x(1:end-1) + rr0/2;
    mask  = (rr0 > rr_min_s) & (rr0 < rr_max_s);
    rr    = rr0(mask);
    tmid  = tmid0(mask);
    if nnz(mask) < 3
        rr = []; tmid = [];
    end
end

function bp = bandpow(f, Pxx, fmin, fmax)
    mask = (f >= fmin) & (f < fmax);
    if ~any(mask)
        bp = NaN;
    else
        bp = trapz(f(mask), Pxx(mask));
    end
end
