% RMSSD figure 

clear; clc;

%% --- Load
infile = 'HRV_vectors_all_participants.mat';
S = load(infile);
HRV = S.HRV_vectors;

%% --- Config
exclude = {'Sub107','Sub133','Sub139','Sub147','Sub151'}; % Excluded participants (poor pulse trace)
dt = 2;                         % step size (seconds)
window = 20;                    % window size (seconds)
lsColor = [1.0 0.498 0.054];    % orange (#ff7f0e) for low-stress run
hsColor = [0.275 0.510 0.705];  % steelblue (#4682B4) for high-stress run
bandColor = [0.7 0.7 0.7];      % darker grey for shaded phases
fontSize = 14;                  % base font size for readability

%% --- Gather subjects and trim to common length
f = setdiff(fieldnames(HRV), exclude);
LS_list = {};
HS_list = {};
minLen = inf;

for i = 1:numel(f)
    s = HRV.(f{i});
    if isfield(s,'LS') && isfield(s,'HS') && ~isempty(s.LS) && ~isempty(s.HS)
        ls = s.LS(:).'; hs = s.HS(:).';
        m = min(numel(ls), numel(hs));
        if m > 0
            LS_list{end+1} = ls(1:m); %#ok<SAGROW>
            HS_list{end+1} = hs(1:m); %#ok<SAGROW>
            minLen = min(minLen, m);
        end
    end
end

LS = cell2mat(cellfun(@(v) v(1:minLen), LS_list, 'UniformOutput', false).');
HS = cell2mat(cellfun(@(v) v(1:minLen), HS_list, 'UniformOutput', false).');
nSubj = size(LS,1);
t = (0:minLen-1) * dt;

%% --- Z-score within participant (across time)
LSz = (LS - mean(LS,2))./max(std(LS,0,2), eps);
HSz = (HS - mean(HS,2))./max(std(HS,0,2), eps);

%% --- Means and SEM
lsMean = mean(LSz,1);  hsMean = mean(HSz,1);
lsSEM  = std(LSz,0,1)/sqrt(nSubj);
hsSEM  = std(HSz,0,1)/sqrt(nSubj);

%% --- Early / Middle / Late masks (20 s each)
earlyMask  = (t >= 0) & (t < window);
midCenter  = t(1) + (t(end) - t(1))/2;
middleMask = (t >= (midCenter - window/2)) & (t < (midCenter + window/2));
lateMask   = (t >= (t(end) - window));

tE = t(earlyMask); e0 = tE(1); e1 = tE(end);
tM = t(middleMask); m0 = tM(1); m1 = tM(end);
tL = t(lateMask); l0 = tL(1); l1 = tL(end);

%% --- Per-subject means and change scores
lsEarly  = mean(LSz(:, earlyMask), 2);
lsMiddle = mean(LSz(:, middleMask),2);
lsLate   = mean(LSz(:, lateMask),  2);
hsEarly  = mean(HSz(:, earlyMask), 2);
hsMiddle = mean(HSz(:, middleMask),2);
hsLate   = mean(HSz(:, lateMask),  2);

dLS_EM = lsMiddle - lsEarly;   dHS_EM = hsMiddle - hsEarly;
dLS_EL = lsLate   - lsEarly;   dHS_EL = hsLate   - hsEarly;

mLS = [mean(dLS_EM) mean(dLS_EL)];
eLS = [std(dLS_EM)/sqrt(nSubj) std(dLS_EL)/sqrt(nSubj)];
mHS = [mean(dHS_EM) mean(dHS_EL)];
eHS = [std(dHS_EM)/sqrt(nSubj) std(dHS_EL)/sqrt(nSubj)];

%% --- Plot
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% ---------- Panel 1: Time course ----------
ax1 = nexttile(1); hold(ax1,'on'); box(ax1,'off'); grid(ax1,'on');

% shaded bands (20-s windows)
yl = [-1.5 1.5];
patch([e0 e1 e1 e0], [yl(1) yl(1) yl(2) yl(2)], bandColor, 'FaceAlpha',0.35, 'EdgeColor','none');
patch([m0 m1 m1 m0], [yl(1) yl(1) yl(2) yl(2)], bandColor, 'FaceAlpha',0.30, 'EdgeColor','none');
patch([l0 l1 l1 l0], [yl(1) yl(1) yl(2) yl(2)], bandColor, 'FaceAlpha',0.35, 'EdgeColor','none');

% SEM ribbons (Low-stress = orange; High-stress = steelblue)
fill([t fliplr(t)], [lsMean+lsSEM fliplr(lsMean-lsSEM)], lsColor, 'FaceAlpha',0.25, 'EdgeColor','none');
fill([t fliplr(t)], [hsMean+hsSEM fliplr(hsMean-hsSEM)], hsColor, 'FaceAlpha',0.25, 'EdgeColor','none');

% means
pLS = plot(t, lsMean, 'Color', lsColor, 'LineWidth',2);
pHS = plot(t, hsMean, 'Color', hsColor, 'LineWidth',2);

xlabel('Time (s)','FontSize',fontSize);
ylabel('RMSSD','FontSize',fontSize);
title('RMSSD time course (20-s window, 2-s step)','FontSize',fontSize+10);
xlim([t(1) t(end)]);
yl = ylim;
legend([pLS pHS], {'Low-stress run','High-stress run'}, ...
    'Location','northwest', 'Box','off', 'FontSize',fontSize);

set(ax1,'FontSize',fontSize);

% ---------- Panel 2: Phase differences ----------
ax2 = nexttile(2); hold(ax2,'on'); box(ax2,'off'); grid(ax2,'on');

% Full phase names on x-axis
X = categorical({'Early\rightarrowMiddle','Early\rightarrowLate'});
X = reordercats(X, {'Early\rightarrowMiddle','Early\rightarrowLate'});

% Bar chart
B = bar(X, [mLS; mHS]','grouped');
B(1).FaceColor = lsColor;
B(2).FaceColor = hsColor;

% error bars
for k = 1:numel(B)
    xk = B(k).XEndPoints;
    if k==1, mk = mLS; ek = eLS; else, mk = mHS; ek = eHS; end
    errorbar(xk, mk, ek, 'k', 'linestyle','none', 'LineWidth',1, 'CapSize',8);
end

yline(0,'Color',[0.2 0.2 0.2],'LineWidth',0.75);
ylabel('\Delta RMSSD','FontSize',fontSize);
title('Phase differences (Early, Middle, Late)','FontSize',fontSize+10);

% significance brackets (between conditions for each phase comparison)
yl2 = ylim; pad = 0.05 * range(yl2);
% Early→Middle
x1 = B(1).XEndPoints(1); x2 = B(2).XEndPoints(1);
y1 = max(mLS(1)+eLS(1), mHS(1)+eHS(1)) + pad;
plot([x1 x1 x2 x2],[y1 y1+pad y1+pad y1],'k','LineWidth',1);
text(mean([x1 x2]), y1+1.6*pad, '*', 'HorizontalAlignment','center', 'FontSize',fontSize+4);
% Early→Late
x1 = B(1).XEndPoints(2); x2 = B(2).XEndPoints(2);
y2 = max(mLS(2)+eLS(2), mHS(2)+eHS(2)) + pad;
plot([x1 x1 x2 x2],[y2 y2+pad y2+pad y2],'k','LineWidth',1);
text(mean([x1 x2]), y2+1.6*pad, '*', 'HorizontalAlignment','center', 'FontSize',fontSize+4);

legend(ax2, {'Low-stress run','High-stress run'}, 'Location','northwest','Box','off','FontSize',fontSize);
set(ax2,'FontSize',fontSize);

set(gcf,'Color','w');
